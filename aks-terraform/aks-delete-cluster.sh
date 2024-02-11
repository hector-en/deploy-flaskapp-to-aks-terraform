#!/bin/bash

# This script deletes an Azure Kubernetes Service (AKS) cluster, its associated Key Vault, and the resource group.

# Define essential variables for Azure and Terraform configurations
servicePrincipalName="AicoretempWebAppSP" # Service principal name
resourceGroupName="secrets-rg"            # Existing resource group
keyVaultName="AicoretempWebappSecrets"    # Key Vault for storing secrets
aksClusterName="webapp-aks-cluster"       # AKS cluster name

# Source automation suite scripts
source ../automation/terraform.sh || { echo "Failed to source terraform.sh"; exit 1; }
source ../automation/azure.sh || { echo "Failed to source azure.sh"; exit 1; }

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

# Fetch Service Principal Id and secrete from KeyVault
setup_service_principal_env_vars

# Call the function to delete AKS resources
# terraform destroy -auto-approve
delete_aks_resources

echo "AKS resource successfully removed."

