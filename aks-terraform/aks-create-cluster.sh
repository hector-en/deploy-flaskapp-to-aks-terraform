#!/bin/bash

# aks-create-cluster.sh: The main orchestration script for automating the deployment of an Azure Kubernetes Service (AKS) cluster.
# This script addresses my github issue #12: Define Main Configuration for AKS Cluster Provisioning Using Terraform.
#
# Task Description:
# The task involves setting up the necessary infrastructure on Azure to deploy a web application using an AKS cluster. It requires:
# - Creating a `main.tf` configuration file with Azure provider and AKS settings.
# - Defining input variables for Azure authentication in a `variables.tf` file.
# - Initializing and applying Terraform configurations to provision the AKS cluster.
# - Ensuring the functionality of the AKS cluster post-creation.
#
# To facilitate these tasks, this script utilizes helper scripts (azure.sh, terraform.sh, functions.sh) to:
# - Authenticate and manage Azure resources via Azure CLI.
# - Automate the creation and deletion of resources like Service Principals and Key Vaults.
# - Handle Terraform files, error recovery, and state management.
# - Install and configure necessary tools such as jq and kubectl.
#
# Usage Instructions:
# 1. Execute the script: ./aks-create-cluster.sh [optional_plan_filename]
#    - Providing a plan filename is optional; if omitted, a new timestamped plan file will be generated.
# 2. Respond to interactive prompts to select desired actions by entering the corresponding digits (e.g., '12' for options 1 and 2).
# 3. Confirm actions when prompted and observe the output for progress updates and further instructions.
#
# The script ensures that all acceptance criteria outlined in Issue #12 are met, providing a seamless and automated process for AKS cluster provisioning.
#
# Additional Script:
# For resource cleanup, the delete-aks-cluster.sh script is provided to deprovision Azure resources when they are no longer required.
#
# Prerequisites:
# Users must have appropriate permissions for Azure resource creation and management and must be logged into the Azure CLI before running this script.


# Enable debugging
# set -x

# Main orchestration script for setting up and managing Azure infrastructure with Terraform.

# Source automation suite scripts
source automation/functions.sh || { echo "Failed to source functions.sh"; exit 1; }
source automation/azure.sh || { echo "Failed to source azure.sh"; exit 1; }
source automation/terraform.sh || { echo "Failed to source terraform.sh"; exit 1; }

# Define essential variables for Azure and Terraform configurations
servicePrincipalName="AicoretempWebAppSP" # Service principal name
resourceGroupName="secrets-rg"            # Existing resource group
keyVaultName="AicoretempWebappSecrets"    # Key Vault for storing secrets
aksClusterName="webapp-aks-cluster"       # AKS cluster name
location="uksouth"                        # Azure resources location
role="Contributor" 
                       # Role for Service Principal
# Prompt user for input options
#user_choices=$(prompt_user_options "$1")
prompt_user_options "$1"

# Ensure necessary tools are installed
ensure_jq_installed
ensure_kubectl_installed

# Verify Azure CLI is authenticated
check_azure_cli_login

# Generate a timestamped Terraform plan filename
plan_filename=$(generate_plan_filename "$1")
echo "Terraform Configuration File: $plan_filename"
echo "Confirming correct SP and KeyVault..."
# Function to check if a digit is in the user's choices
is_selected() {
  [[ $user_choices =~ $1 ]]
}

# Execute actions based on user's choices
if is_selected 1; then
  ensure_azure_sp_keyvault  # Provision SP and KeyVault if chosen.
else
  setup_service_principal_env_vars  # Otherwise,  store SP details in environment.
fi

if is_selected 2; then
  delete_terraform_files  # Remove existing Terraform files if chosen.
  create_terraform_configuration_files  # Create new config files.
  run_solution_scripts  # # Execute module creation scripts.
fi

if is_selected 3; then
  terraform_init_and_plan  # Reinitialize Terraform if chosen.
fi

# Confirm and apply the Terraform plan, handling errors as needed
if confirm_plan_apply; then
  if check_plan_file_exists "$plan_filename"; then
    apply_terraform_plan_and_handle_errors
    verify_and_check_aks_cluster
  fi
else
  echo "Plan not applied by user request."
fi