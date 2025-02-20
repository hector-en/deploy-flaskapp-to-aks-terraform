#!/bin/bash
#
# init.sh: Initializes the AKS Terraform/Kubernetes cluster framework
# Usage:
# ./init.sh 
#
# Prerequisites: Azure CLI login with necessary permissions.

# Enable debugging
# set -x
# Check if PROJECT_ROOT is set. 
if [ -z "$PROJECT_ROOT" ]; then
  : # echo "PROJECT_ROOT is not set. Setting it now..."
  # Determine the project root directory
  export PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: $PROJECT_ROOT."
# Source cluster configuration scripts
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }
# Source automation helper scripts
source "$SCRIPTS_DIR/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }
source "$SCRIPTS_DIR/utilities/azure.sh" || { echo "Failed to source azure.sh"; exit 1; }
source "$SCRIPTS_DIR/utilities/terraform.sh" || { echo "Failed to source terraform.sh"; exit 1; }
source "$SCRIPTS_DIR/libraries/dialog-utilities.sh" || { echo "Failed to source dialog-utilities.sh"; exit 1; }

# Uncomment automation
user_choices="${1:-"1"}"  # Options: 1 (setup & terraform) 2 (terraform only) 3 (setup only)
# Uncomment for interactive version
# prompt_user_options "$1"

# Ensure necessary tools are installed
ensure_jq_installed
ensure_kubectl_installed
setup_env_vars # write env variables

# Function to check if a digit is in the user's choices
is_selected() {
  [[ $user_choices =~ $1 ]]
}

# Execute actions based on user's choices using a case statement
case "$user_choices" in
  *3*) # infracstructure, terraform and kubernetes workflow
    confirm_delete="Yes" # Hardcoded for automation
    run_setup_scripts # Execute module creation scripts.
    ;&  # Fall-through to next pattern  
  *2*) # terraform workflow with apply
    echo "Initialising AKS Cluster ..."
    terraform_init #|| exit 1
    terrafor_plan
    #confirm_plan_apply
    # Check if confirm_plan_apply returned 1 (fail)
    if [ $? -eq 1 ]; then
    # Select a different plan or quit
    #present_plan_options_and_apply
    return 1
    fi
    # Apply the Terraform plan
    pushd "$TF_ENV_DIR"
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
    run_setup_scripts # Execute module creation scripts.
    ;;
esac
# Define ANSI color codes for colored output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# After the case statement and all initialization logic:
output_message="${GREEN}The AKS Terraform/Kubernetes cluster framework is now ready.${NC}\n"
output_message+="You can now:\n\n"
output_message+="${YELLOW}- Configure${NC} individual environments using the .tfvars files in the 'terraform' folder.\n"
output_message+="${YELLOW}- Adapt${NC} the Kubernetes overlays in the 'kubernetes/overlays' folder as needed.\n"
output_message+="${YELLOW}- Use 'bash rollout.sh <environment>'${NC} to plan infrastructure changes for a specific environment and save the plan in the '.plans' folder.\n"
output_message+="${YELLOW}- Use 'bash deploy.sh <environment | plan>'${NC} to deploy your application onto the AKS cluster using the saved plan or directly from a selected terraform environment workspace.\n"
output_message+="${YELLOW}- Use 'bash deploy.sh'${NC} to see available environments.\n"

# Display the message in the shell
echo -e "$output_message"
