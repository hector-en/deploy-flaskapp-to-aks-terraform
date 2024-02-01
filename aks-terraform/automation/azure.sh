#!/bin/bash

# This script contains functions for creating and deleting Azure resources.
# The ensure_azure_sp_keyvault function checks if the AKS cluster and Key Vault exist, and creates them using the create_keyvault_and_store_secrets function if they don't.
# The delete_azure_resources function deletes the AKS cluster and Key Vault.
# The create_keyvault_and_store_secrets function creates an Azure Key Vault in an existing resource group and stores the client_id and client_secret as secrets in it.
# These functions are intended to be sourced and used in other scripts.

# Check if the user is logged in to the Azure CLI
az account show &> /dev/null
if [ $? -ne 0 ]
then
  echo "Please log in to the Azure CLI"
  exit
fi

# Function to check and create Azure resources
function ensure_azure_sp_keyvault() {
  # Variables for the loop
 local continueLoop=true

  while $continueLoop; do
    echo "Ensure SP and KeyVault availability..."
    # Display information about the AKS cluster and the Key Vault, and ask the user to verify if the required modules have been created
    if ! az aks show --name $aksClusterName --resource-group $resourceGroupName &>/dev/null || ! az keyvault show --name $keyVaultName &>/dev/null; then      
      # Check if the user is in the sudoers list
      if sudo -l | grep -q "(ALL : ALL) ALL"
      then
        create_resource_group_keyvault_and_store_secrets
      else
        echo "Insufficient rights to create the required Azure resources. Please contact your account administrator."
        exit
      fi
    else 
      setup_service_principal_env_vars
      create_or_display_resource_group_info
      create_or_display_keyvault_info
    fi

    # Assign Role to the Service Principal and proceed with AKS creation
      echo "Assigning Role ($role)..."
      assign_role $role
      continueLoop=false
  done
}

# Function to retrieve secrets from Key Vault and assign role to service principal
# Usage:
# assign_role "RoleName" 
assign_role() {
  local RoleName=$1
  # Retrieve the client_id and client_secret from the Key Vault
  local clientId=$(az keyvault secret show --name client-id --vault-name $keyVaultName --query value -o tsv)
  local clientSecret=$(az keyvault secret show --name client-secret --vault-name $keyVaultName --query value -o tsv)

  # Check if clientId and clientSecret are set
  if [ -z $clientId ] || [ -z $clientSecret ]; then
    echo "Error: Client ID or Client Secret is empty."
    exit 1
  fi

  # Retrieve the appId and subscription_id from the Azure KeyVault
  local appId=$(az keyvault secret show --name client-id --vault-name $keyVaultName --query value -o tsv)
  local subscriptionId=$(az account show --query id -o tsv)
  # Check if tenantId and subscriptionId are set
  if [ -z $appId ] || [ -z $subscriptionId ]; then
    echo "Error: App ID or Subscription ID is empty."
    exit 1
  fi

  # Assign the 'Contributor' role to the service principal for the entire subscription
  if az role assignment create --assignee $appId --role $RoleName --scope "/subscriptions/$subscriptionId" &>/dev/null; then
    # Command succeeded; do nothing or perform additional silent actions
    :
  else
    # Command failed; retrieve the exit status of the command
    status=$?
    echo "Failed to create role assignment. Exit status: $status"  
    Exit 1
  fi
}

# Function to create a resource group, Key Vault, and store secrets
function create_resource_group_keyvault_and_store_secrets() {
    # Create a resource group
    create_or_display_resource_group_info 
    # Create a Key Vault in the existing resource group
    create_or_display_keyvault_info  
  # Check if the service principal exists
    appId=$(az ad sp list --display-name $servicePrincipalName --query "[?appDisplayName=='$servicePrincipalName'].appId" -o tsv)
    if [ -z $appId ]
    then
      # Create a new service principal and retrieve the client_id and client_secret
      echo "Creating a new service principal ($servicePrincipalName)..."
      local spDetails=$(az ad sp create-for-rbac --name $servicePrincipalName)
      local clientId=$(echo $spDetails | jq -r .appId)
      local clientSecret=$(echo $spDetails | jq -r .password)
      echo "$servicePrincipalName details: $spDetais"
      echo "Client ID: $clientId"
      echo "Client Secret: $clientSecret"
      # Check if clientId and clientSecret are set
      if [ -z $clientId ] || [ -z $clientSecret ]; then
          echo "Error: Client ID or Client Secret is empty."
          exit 1
      fi
      # Store the client ID and client secret in the Key Vault
      echo "Storing secrets in the Key Vault ($keyVaultName)..."
      az keyvault secret set --vault-name $keyVaultName --name "client-id" --value $clientId
      az keyvault secret set --vault-name $keyVaultName --name "client-secret" --value $clientSecret
      # Check for errors after each command
      if [ $? -ne 0 ]; then
          echo "Failed to store the secret in the Key Vault."
          exit 1
      fi
    else
      # Retrieve information about the existing service principal
      setup_service_principal_env_vars    
  fi
   

    echo "Resource group $resourceGroupName, Key Vault $keyVaultName and $servicePrincipalName are ready, and secrets stored."
}

# Function retrieves and sets Service Principal credentials as environment variables for Terraform.
function setup_service_principal_env_vars() {

    # Retrieve the appId (clientId) and client_secret from the Key Vault
    local clientId=$(az keyvault secret show --name client-id --vault-name $keyVaultName --query value -o tsv)
    local clientSecret=$(az keyvault secret show --name client-secret --vault-name $keyVaultName --query value -o tsv)
    # Check if clientId and clientSecret are set
    if [ -z $clientId ] || [ -z $clientSecret ]; then
        echo "Error: Client ID or Client Secret is empty."
        echo "Reseting the Client Secret and Client ID for $servicePrincipalName and storing it in $keyVaultName. "
        reset_client_secret_and_store $keyVaultName $servicePrincipalName       
        #exit 1
    fi
    # Export the client_id and client_secret as environment variables
    export TF_VAR_client_id=$clientId
    export TF_VAR_client_secret=$clientSecret
  
    # Retrieve the tenant_id and subscription_id from the Azure CLI
    tenantId=$(az account show --query tenantId -o tsv)
    subscriptionId=$(az account show --query id -o tsv)
    # Check if tenantId and subscriptionId are set
    if [ -z $tenantId ] || [ -z $subscriptionId ]; then
      echo "Error: Tenant ID or Subscription ID is empty."
      exit 1
    fi
    # Export the tenant_id and subscription_id as environment variables
    export TF_VAR_tenant_id=$tenantId
    export TF_VAR_subscription_id=$subscriptionId
    
    echo "The clientId for the service principal '$servicePrincipalName' is: $clientId"
    # Retrieve service principal metadata using its appId (clientId)
    spMetadata=$(az ad sp show --id $clientId -o json)

    # Check if the service principal metadata was successfully retrieved
    if [ -z "$spMetadata" ]; then
        echo "Service principal with clientId '$clientId' does not exist or could not be retrieved."
    else
        echo "Service principal exists." # Metadata:
        # echo "$spMetadata"
    fi
}

# Function to reset client secret and store in Key Vault
# Usage:
# reset_client_secret_and_store "YourKeyVaultName" "YourServicePrincipalName"
function reset_client_secret_and_store() {
  local keyVaultName=$1
  local servicePrincipalName=$2

  # Retrieve the appId (clientId) of the service principal
  local clientId=$(az ad sp list --display-name $servicePrincipalName --query "[?appDisplayName=='$servicePrincipalName'].appId" -o tsv)


  # Check if clientId is set
  if [ -z $clientId ]; then
    echo "Error: Client ID is empty."
    exit 1
  fi

  # Store or update the client ID in the Key Vault
  az keyvault secret set --vault-name $keyVaultName --name "client-id" --value $clientId

  # Generate a new client secret for the service principal
  local newClientSecret=$(az ad sp credential reset --id $clientId --query password -o tsv)

  # Check if newClientSecret is set
  if [ -z $newClientSecret ]; then
    echo "Error: Failed to create a new Client Secret."
    exit 1
  fi

  # Store the new client secret in the Key Vault
  az keyvault secret set --vault-name $keyVaultName --name "client-secret" --value $newClientSecret

  echo "New Client Secret ID has been created and stored in the Key Vault: $keyVaultName."
  echo "Client ID: $clientId"
  echo "Client Secret: $newClientSecret."
}

# Verifies AKS cluster existence and connectivity.
function verify_and_check_aks_cluster() {
  # Retrieve variables from Terraform outputs
  local TfAksClusterName=$(terraform output aks_cluster_name | tr -d '"')
  local TfResourceGroupName=$(terraform output -raw resource_group_name | tr -d '"')
  
  echo "Verifying and testing Cluster: $TfAksClusterName..."
 # Check if the resourceGroupName variable is set
  if [ -z "$TfResourceGroupName" ]; then
      echo "Error: Unable to retrieve the resource group name from Terraform outputs."
      exit 1
  fi
  # Retrieve the AKS cluster name from the resource group
  #local aksClusterName=$(az aks list --resource-group $resourceGroupName --query "[].name" -o tsv)


  # Check if the AKS cluster exists
  local aksClusterExists=$(az aks list --resource-group $TfResourceGroupName --query "[?name=='$TfAksClusterName'] | length(@)" -o tsv)

  if [ $aksClusterExists -eq 0 ]; then
    echo "AKS cluster $TfAksClusterName under resource group $TfResourceGroupName does not exist."
  else
    # Display the output
    echo "The AKS cluster $TfAksClusterName has been created."

    # echo "Displaying the AKS cluster information..."
    # az aks show --name $TfAksClusterName --resource-group $TfResourceGroupName

    # Retrieve the kubeconfig file for the AKS cluster
    echo "Retrieving the kubeconfig file for the AKS cluster..."
    az aks get-credentials --resource-group $TfResourceGroupName --name $TfAksClusterName
  
    # Test the connection to the AKS cluster
    echo "Testing the connection to the AKS cluster..."
    kubectl get nodes
  fi
}

function create_or_display_keyvault_info() {
  # Check if the Key Vault exists
  local keyVaultExists=$(az keyvault list --resource-group $resourceGroupName --query "[?name=='$keyVaultName'] | length(@)" -o tsv)

  if [ $keyVaultExists -eq 0 ]; then
    echo "Key Vault does not exist."
    echo "Creating Key Vault ($keyVaultName) under resource group $resourceGroupName ..."
    az keyvault create --name $keyVaultName --resource-group $resourceGroupName
  else
    :
    # echo "Displaying the Key Vault ($keyVaultName) information..."
    # az keyvault show --name $keyVaultName --resource-group $resourceGroupName
  fi
}

function create_or_display_resource_group_info() {
  # Check if the Resource Group exists
  local resourceGroupExists=$(az group exists --name $resourceGroupName)

  if [ "$resourceGroupExists" == "false" ]; then
    echo "Resource group does not exist."
    echo "Creating $resourceGroupName for $location ..."
    az group create --name $resourceGroupName --location $location

  else
    :
    # echo "Displaying the Resource Group information ($resourceGroupName)..."
    # az group show --name $resourceGroupName
  fi
}

# Function to delete Azure resources
function delete_aks_resources() {
  # Warn the user about the irreversible action of deleting resources.
  echo "WARNING: This will permanently delete the AKS cluster, Key Vault and resource group."
  
  # Prompt for user confirmation before proceeding.
  read -p "Are you sure you want to continue? There is NO undo! [yes/no]: " confirm_delete
  
  if [[ $confirm_delete =~ ^[Yy] ]]; then
    # Retrieve the resource group name from Terraform outputs
    local resourceGroupName=$(terraform output -raw resource_group_name)
    # Check if the resourceGroupName variable is set
    if [ -z "$resourceGroupName" ]; then
        echo "Error: Unable to retrieve the resource group name from Terraform outputs."
        exit 1
    fi
    # Retrieve the AKS cluster name from the resource group
    local aksClusterName=$(az aks list --resource-group $resourceGroupName --query "[].name" -o tsv)

    # Delete the AKS cluster
    echo "Deleting the AKS cluster ($aksClusterName)..."
    az aks delete --name $aksClusterName --resource-group $resourceGroupName --yes --no-wait

    # Delete the Key Vault after explaining its purpose
    echo "The Azure Key Vault ($keyVaultName) stores secrets and cryptographic keys securely. Deleting it will remove all stored items permanently."
    read -p "Are you sure you want to delete the Key Vault? This action cannot be undone. [yes/no]: " confirm_kv_delete

    if [[ $confirm_kv_delete =~ ^[Yy] ]]; then
      echo "Proceeding with deletion of the Key Vault ($keyVaultName)..."
      az keyvault delete --name "$keyVaultName" --resource-group "$resourceGroupName"
      echo "Key Vault deletion initiated..."
    else
      echo "Key Vault deletion cancelled by user."
    fi
    # Delete the resource group
    echo "Deleting the resource group ($resourceGroupName)..."
    az group delete --name $resourceGroupName --yes --no-wait

    echo "The AKS cluster, Key Vault, and resource group have been deleted."
  else
    echo "Resource deletion cancelled by user."
  fi
}