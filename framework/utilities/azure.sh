#!/bin/bash
# azure.sh
# This script contains functions for creating and deleting Azure resources.
# The create_new_sp_and_keyvault function checks if the AKS cluster and Key Vault exist, and creates them using the create_keyvault_and_store_secrets function if they don't.
# The delete_azure_resources function deletes the AKS cluster and Key Vault.
# The create_keyvault_and_store_secrets function creates an Azure Key Vault in an existing resource group and stores the client_id and client_secret as secrets in it.
# These functions are intended to be sourced and used in other scripts.

# Source Azure Library
source "$SCRIPTS_DIR/libraries/azure_commands.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/azure_commands.sh"; exit 1; }


# Check if the user is logged in to the Azure CLI
az account show &> /dev/null
if [ $? -ne 0 ]; then
  echo "Please log in to the Azure CLI."
  #az login # Use a non-zero exit code to indicate an error
fi

# Function to check and create Azure resources
function create_new_sp_and_keyvault() {
  # Variables for the loop
 local continueLoop=true

  while $continueLoop; do
      # Check if the user is in the sudoers list
      if sudo -l | grep -q "(ALL : ALL) ALL"
      then      
       create_sp_and_store_secrets
       create_or_display_resource_group_info $Secrets_rg
       create_or_display_keyvault_info
      else
        echo "Insufficient rights to create the required Azure resources. Please contact your account administrator."
        exit
      fi
    # Assign Role to the Service Principal and proceed with AKS creation
      #echo "Assigning Role ($ROLE)..."
      #assign_role $ROLE
      continueLoop=false
  done
}

# Function to retrieve secrets from Key Vault and assign role to service principal
# Usage:
# assign_role "RoleName" 
assign_role() {
  local RoleName=$1
  # Retrieve the client_id and client_secret from the Key Vault
  local clientId=$(az keyvault secret show --name client-id --vault-name $KEY_VAULT_NAME --query value -o tsv)
  local clientSecret=$(az keyvault secret show --name client-secret --vault-name $KEY_VAULT_NAME --query value -o tsv)

  # Check if clientId and clientSecret are set
  if [ -z $clientId ] || [ -z $clientSecret ]; then
    echo "Error: Client ID or Client Secret is empty."
    exit 1
  fi

  # Retrieve the appId and subscription_id from the Azure KeyVault
  local appId=$(az keyvault secret show --name client-id --vault-name $KEY_VAULT_NAME --query value -o tsv)
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


# Function to check if Azure CLI is installed
function check_azure_cli() {
    if ! command -v az &> /dev/null; then
        echo "Azure CLI could not be found. Please install it to proceed."
        exit 1
    fi
}

# Function to retrieve and export tenant and subscription IDs
export_tenant_and_subscription_ids() {
    local tenantId=$(az account show --query tenantId -o tsv)
    local subscriptionId=$(az account show --query id -o tsv)

    if [ -z "$tenantId" ] || [ -z "$subscriptionId" ]; then
        echo "Error: Tenant ID or Subscription ID is empty."
        exit 1
    fi

    export TF_VAR_tenant_id=$tenantId
    export TF_VAR_subscription_id=$subscriptionId
}

# Function to automatically handle service principal operations
automatic_sp_operations() {
    local operation=$1

    case $operation in
        "create_new_sp")
            # Logic to create a new Service Principal (SP)
            if create_new_sp_and_keyvault; then
                return 0
            else
                return 1
            fi
            ;;
        "enter_new_sp")
            # Logic to prompt user for a new Service Principal name and create it
            read -p "Enter a new Service Principal name to create: " newSpName
            servicePrincipalName="$newSpName"
            if create_new_sp_and_keyvault; then
                return 0
            else
                return 1
            fi
            ;;
        "reset_credentials")
            # Logic to reset credentials for the existing Service Principal
            if reset_client_secret_and_store "$KEY_VAULT_NAME" "$servicePrincipalName"; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            echo "Invalid operation specified."
            return 1
            ;;
    esac
}

# Function to handle missing service principal credentials
handle_missing_sp_credentials() {
    echo "The Client ID or Client Secret could not be found in Key Vault '$KEY_VAULT_NAME'."
    user_action="reset"
    #read -p "Would you like to create a new Service Principal or reset the existing credentials? (create/reset/quit): " user_action

    case $user_action in
        create)
            # Call function to create a new Service Principal
            automatic_sp_operations "create_new_sp"
            ;;
        reset)
            # Call function to reset credentials for the existing Service Principal
            automatic_sp_operations "reset_credentials"
            ;;
        quit)
            # Exit the script if the user decides to quit
            echo "User opted to quit. Exiting without making changes."
            exit 0
            ;;
        *)
            # Handle invalid input
            echo "Invalid selection. Please enter 'create', 'reset', or 'quit'."
            exit 1
            ;;
    esac
}

# Function to check for forbidden access error and grant permissions if needed
check_and_grant_sp_permissions() {
    local key_vault_name=$1
    local service_principal_name=$2

    # Attempt to retrieve a secret to test permissions
    local test_secret_retrieval=$(az keyvault secret list --vault-name "$key_vault_name" --query "[0].id" -o tsv 2>&1)

    # Check if the retrieval resulted in a Forbidden error
    if [[ $test_secret_retrieval == *"ERROR: (Forbidden)"* ]]; then
        echo "The Service Principal does not have sufficient permissions on Key Vault '$key_vault_name'."
        echo "Granting 'get', 'list', 'set', and 'delete' permissions to the Service Principal: $service_principal_name..."
        grant_sp_keyvault_access "$key_vault_name" "$service_principal_name"
    fi
}

# Function to retrieve and export service principal credentials
export_service_principal_credentials() {
    # Ensure SP can retrieve credentials from keyvault
    check_and_grant_sp_permissions "$KEY_VAULT_NAME" "$servicePrincipalName"
    local clientId=$(az keyvault secret show --name client-id --vault-name $KEY_VAULT_NAME --query value -o tsv 2>&1)
    local clientSecret=$(az keyvault secret show --name client-secret --vault-name $KEY_VAULT_NAME --query value -o tsv 2>&1)

    # Check for errors indicating the secret was not found
    if [[ $clientId == *"SecretNotFound"* ]] || [[ $clientSecret == *"SecretNotFound"* ]]; then
        handle_missing_sp_credentials
        # After handling, attempt to retrieve the credentials again
        clientId=$(az keyvault secret show --name client-id --vault-name $KEY_VAULT_NAME --query value -o tsv 2>&1)
        clientSecret=$(az keyvault secret show --name client-secret --vault-name $KEY_VAULT_NAME --query value -o tsv 2>&1)
    fi

    # Check if clientId and clientSecret are still empty after handling
    if [ -z "$clientId" ] || [ -z "$clientSecret" ]; then
        echo "Failed to obtain Client ID or Client Secret after handling. Exiting."
        exit 1
    fi

    # Export the retrieved credentials
    export TF_VAR_client_id=$clientId
    export TF_VAR_client_secret=$clientSecret
    # Try loging in with the credentials
    login_service_principal "$TF_VAR_client_id" "$TF_VAR_client_secret"
}

# Function to create a resource group, Key Vault, and store secrets
# Usage:
# reset_client_secret_and_store "YourKeyVaultName" "YourServicePrincipalName"
function create_sp_and_store_secrets() {
    # Create a resource group
    create_or_display_resource_group_info $Secrets_rg
    # Create a Key Vault in the existing resource group
    create_or_display_keyvault_info  
  # Check if the service principal exists
    appId=$(az ad sp list --display-name $servicePrincipalName --query "[?appDisplayName=='$servicePrincipalName'].appId" -o tsv)
    local subscriptionId=$(az account show --query id -o tsv)

    if [ -z $appId ]
    then
      # Create a new service principal and retrieve the client_id and client_secret
      echo "Creating a new service principal ($servicePrincipalName)..."
      local spDetails=$(az ad sp create-for-rbac --name $servicePrincipalName --role="Contributor" --scopes="/subscriptions/$subscriptionId")
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
      echo "Storing secrets in the Key Vault ($KEY_VAULT_NAME)..."
      az keyvault secret set --vault-name $KEY_VAULT_NAME --name "client-id" --value $clientId
      az keyvault secret set --vault-name $KEY_VAULT_NAME --name "client-secret" --value $clientSecret
    
      # Check for errors after storing secrets
      if [ $? -ne 0 ]; then
          echo "Failed to store the secret in the Key Vault."
          exit 1
      fi
    else
        echo "Service principal $servicePrincipalName already exists."
    fi
    echo "Resource group $Secrets_rg, Key Vault $KEY_VAULT_NAME, and Service Principal $servicePrincipalName are ready, and secrets stored."
  }

echo "Azure funtions are now available."