#!/bin/bash
# aks-create-cluster.sh: Automates AKS cluster deployment on Azure.
#
# Sets up Azure infrastructure for deploying a web application on AKS, including:
# - Creation and application of Terraform configurations.
# - Validation of the AKS cluster post-deployment.
#
# Utilizes helper scripts for Azure authentication, resource management, error handling, and tool configuration.
#
# Usage:
# ./aks-create-cluster.sh <environment>
# - Required: Specify the environment (dev, prod, staging).
#
# Prerequisites: Azure CLI login with necessary permissions.

# Enable debugging
# set -x
# Set the Terraform environment based on the first argument
export TF_ENV=$1
export K8S_ENV=${1:-$1}

# Check if PROJECT_ROOT is set. 
if [ -z "$PROJECT_ROOT" ]; then
  : # echo "PROJECT_ROOT is not set. Setting it now..."
  # Determine the project root directory
  export PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: $PROJECT_ROOT."
# Source cluster configuration scripts
source "$PROJECT_ROOT/azure-devops/shell/conf/cluster-config.sh" || { echo "Failed to source $PROJECT_ROOT/azure-devops/shell/conf/cluster-config.sh"; exit 1; }


# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo ""
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  # Check if a kubernetes namespace was provided
  if [ -z "$2" ]; then
    echo "(Optional): namespaces for the '$K8S_ENV' environment:"
    awk '/name:/{print $2}' $K8S_OVERLAYS_DIR/$K8S_ENV/namespaces.yaml
  fi
echo ""
echo "Usage: $0 <env> <env-namespace (optional)>"
exit 1
fi


# Source automation helper scripts
source "$AZURE_DEVOPS_SCRIPTS_DIR/conf/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/util/azure.sh" || { echo "Failed to source azure.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/util/terraform.sh" || { echo "Failed to source terraform.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_dialogs.sh" || { echo "Failed to source /lib/tf_dialogs.sh"; exit 1; }

# Uncomment automation
user_choices="${3:-"3"}"  # Options: 1 (setup & terraform) 2 (terraform only) 3 (setup only)
# Uncomment for interactive version
# prompt_user_options "$1"

# Ensure necessary tools are installed
ensure_jq_installed
ensure_kubectl_installed

# Function to check if a digit is in the user's choices
is_selected() {
  [[ $user_choices =~ $1 ]]
}

# Execute actions based on user's choices using a case statement
case "$user_choices" in
  *3*) # infracstructure and full workflow
    confirm_delete="Yes" # Hardcoded for automation
    #echo "Removing  AKS Files ..."
    #delete_terraform_files  # Remove existing Terraform files if chosen.
    run_setup_scripts $TF_ENV $K8S_ENV # Execute module creation scripts.
    ;&  # Fall-through to next pattern  
  *2*) # full terraform workflow
    echo "Initialising AKS Cluster ..."
    setup_env_vars
    init_plan #|| exit 1
    #confirm_plan_apply
    # Check if confirm_plan_apply returned 1 (fail)
    if [ $? -eq 1 ]; then
    # Select a different plan or quit
    present_plan_options_and_apply
    fi
    # Apply the Terraform plan
    pushd "$TF_ENV_DIR/$TF_ENV"
    if ! apply_terraform_plan_and_handle_errors "$plan"; then
      echo "Terraform apply failed. Cannot proceed to verify and check AKS cluster."
      popd > /dev/null  # Return to the original directory
      return 1
    fi
    # Verify and check the AKS cluster
    verify_and_check_aks_cluster
    ;;
  *1*) # infrastructure only
    confirm_delete="Yes" # Hardcoded for automation
    run_setup_scripts $TF_ENV $K8S_ENV # Execute module creation scripts.
    ;;
esac
