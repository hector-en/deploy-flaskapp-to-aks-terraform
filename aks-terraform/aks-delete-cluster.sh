#!/bin/bash

# This script deletes an Azure Kubernetes Service (AKS) cluster, its associated Key Vault, and the resource group.

# Function to delete AKS resources
delete_aks_resources() {
  # Retrieve the resource group name from Terraform outputs
  local resourceGroupName=$(terraform output -raw resource_group_name)
  
  # Check if the resourceGroupName variable is set
  if [ -z "$resourceGroupName" ]; then
      echo "Error: Unable to retrieve the resource group name from Terraform outputs."
      exit 1
  fi
  
  # Retrieve the AKS cluster name from the resource group
  local aksClusterName=$(az aks list --resource-group $resourceGroupName --query "[].name" -o tsv)

  # Check if the AKS cluster name is retrieved
  if [ -z "$aksClusterName" ]; then
      echo "Error: Unable to retrieve the AKS cluster name from the resource group."
      exit 1
  fi

  # Delete the AKS cluster
  echo "Deleting the AKS cluster ($aksClusterName)..."
  az aks delete --name $aksClusterName --resource-group $resourceGroupName --yes --no-wait

  # Retrieve the Key Vault name from Terraform outputs
#  local keyVaultName=$(terraform output -raw key_vault_name)

  # Check if the Key Vault name is retrieved
 # if [ -z "$keyVaultName" ]; then
 #     echo "Error: Unable to retrieve the Key Vault name from Terraform outputs."
 #     exit 1
 # fi

  # Delete the Key Vault
#  echo "Deleting the Key Vault ($keyVaultName)..."
#  az keyvault delete --name $keyVaultName --resource-group $resourceGroupName

  # Delete the resource group
  echo "Deleting the resource group ($resourceGroupName)..."
  az group delete --name $resourceGroupName --yes --no-wait

  echo "The AKS cluster ($aksClusterName) and and resource group ($resourceGroupName) have been deleted."
}

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

# Call the function to delete AKS resources
delete_aks_resources
