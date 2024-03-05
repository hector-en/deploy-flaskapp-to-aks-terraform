#!/bin/bash
# delete-cluster.sh

# This script deletes an Azure Kubernetes Service (AKS) cluster, its associated Key Vault, and the resource group.
# Check if PROJECT_ROOT is set. 
if [ -z "$PROJECT_ROOT" ]; then
  : # echo "PROJECT_ROOT is not set. Setting it now..."
  # Determine the project root directory
  export PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: $PROJECT_ROOT."
# Source cluster configuration scripts
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source $PROJECT_ROOT/framework/cluster-management/cluster-config.sh"; exit 1; }

# Ensure the Azure CLI is installed and configured
if ! command -v az &> /dev/null; then
    echo "Azure CLI could not be found. Please install it before running this script."
    exit 1
fi

# Ensure the user is logged in to Azure
if ! az account show > /dev/null; then
    echo "You are not logged in to Azure. Please log in using 'az login' before running this script."
    exit 1
fi

# Navigate to the Terraform directory
pushd "$TF_ENV_DIR/" || exit
source "$PROJECT_ROOT/framework/cluster-management/cluster-output.sh" || { echo "Failed to source $PROJECT_ROOT/framework/cluster-management/cluster-config.sh"; exit 1; }

# Fetch Service Principal Id and secrete from KeyVault
setup_env_vars

# Call the function to delete AKS resources
# terraform destroy -auto-approve
delete_aks_resources

echo "AKS resource successfully removed."

popd