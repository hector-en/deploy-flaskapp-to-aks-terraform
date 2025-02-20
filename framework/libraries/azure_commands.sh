# azure-commands.sh:
# Function to login using the Service Principal
function login_service_principal() {  
    local TF_VAR_client_id=$1  
    local TF_VAR_client_secret=$2
# Check if already logged in to Azure CLI
    if ! az account show > /dev/null 2>&1; then
        echo "You are not logged in to Azure CLI."
        echo "Logging in ..."
        # Log in to the specified tenant
        az login --tenant "$TF_VAR_tenant_id" --allow-no-subscriptions
        echo "Logged in to tenant '$TF_VAR_tenant_id'."
    else
      :
    fi  
    
    echo "Attempting to log in with the Service Principal..."
    az login --service-principal -u "$TF_VAR_client_id" -p "$TF_VAR_client_secret" --tenant "$TF_VAR_tenant_id" &> /dev/null
    
    if [ $? -eq 0 ]; then
        echo "Login successful. Service Principal credentials are valid."
    else
        echo "Login failed. Please check the Service Principal credentials and try again."
        exit 1
    fi
}

# Function to grant Service Principal access to Key Vault secrets
# Usage:
# Call the function with the Key Vault name and Service Principal display name
# grant_sp_keyvault_access "$KEY_VAULT_NAME" "$SERVICE_PRINCIPAL_DISPLAY_NAME"
grant_sp_keyvault_access() {
    local key_vault_name=$1
    local service_principal_display_name=$2

    # Retrieve the Service Principal Application (Client) ID using its display name
    local service_principal_app_id=$(az ad sp list --display-name "$service_principal_display_name" --query "[].appId" -o tsv)

    if [ -z "$service_principal_app_id" ]; then
        echo "Error: Unable to find a Service Principal with the display name '$service_principal_display_name'."
        return 1
    fi

    echo "Key Vault Name: $key_vault_name"
    echo "Service Principal Application (Client) ID: $service_principal_app_id"
    
    # Grant the Service Principal access to the Key Vault secrets
    az keyvault set-policy --name "$key_vault_name" \
                           --spn "$service_principal_app_id" \
                           --secret-permissions get list set delete #recover backup restore purge
    delete > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "Access policy set successfully for Service Principal on Key Vault '$key_vault_name'."
        return 0
    else
        echo "Failed to set access policy for Service Principal on Key Vault '$key_vault_name'."
        return 1
    fi
}


function create_or_display_resource_group_info() {
  RESSOURCE_GROUP_NAME=$1
  # Check if the Resource Group exists
  local resourceGroupExists=$(az group exists --name $RESSOURCE_GROUP_NAME)

  if [ "$resourceGroupExists" == "false" ]; then
    echo "Resource group does not exist."
    echo "Creating $RESSOURCE_GROUP_NAME for $RG_LOCATION ..."
    az group create --name $RESSOURCE_GROUP_NAME --location $RG_LOCATION

  else
    :
    # echo "Displaying the Resource Group information ($RESSOURCE_GROUP_NAME)..."
    # az group show --name $RESSOURCE_GROUP_NAME
  fi
}

function create_or_display_keyvault_info() {
  # Check if the Key Vault exists
  local keyVaultExists=$(az keyvault list --resource-group $Secrets_rg --query "[?name=='$KEY_VAULT_NAME'] | length(@)" -o tsv)

  if [ $keyVaultExists -eq 0 ]; then
    echo "Key Vault does not exist."
    echo "Creating Key Vault ($KEY_VAULT_NAME) under resource group $Secrets_rg ..."
    az keyvault create --name $KEY_VAULT_NAME --resource-group $Secrets_rg
  else
    :
    # echo "Displaying the Key Vault ($KEY_VAULT_NAME) information..."
    # az keyvault show --name $KEY_VAULT_NAME --resource-group $Secrets_rg
  fi
}

# Function to reset the client secret of a service principal and store it in Azure Key Vault
function reset_client_secret_and_store() {
  local KEY_VAULT_NAME=$1
  local servicePrincipalName=$2

  # Retrieve the appId (clientId) of the service principal
  local clientId=$(az ad sp list --display-name "$servicePrincipalName" --query "[?appDisplayName=='$servicePrincipalName'].appId" -o tsv)

  # Check if clientId is set
  if [ -z "$clientId" ]; then
    echo "Error: Client ID for '$servicePrincipalName' could not be found."
    exit 1
  fi

  # Store or update the client ID in the Key Vault
  az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "client-id" --value "$clientId"

  # Generate a new client secret for the service principal
  local newClientSecret=$(az ad sp credential reset --id "$clientId" --query password -o tsv)

  # Check if newClientSecret is set
  if [ -z "$newClientSecret" ]; then
    echo "Error: Failed to create a new Client Secret."
    exit 1
  fi

  # Store the new client secret in the Key Vault
  az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "client-secret" --value "$newClientSecret"

  echo "New Client Secret has been created and stored in the Key Vault: $KEY_VAULT_NAME."
  echo "Client ID: $clientId"
  # For security reasons, do not output the new client secret
}

# Function to confirm that the service principal, resource group, and key vault exist on Azure and match the given values
confirm_azure_resources_match() {
    # Check if the service principal exists and matches the given name
    local sp_match=$(az ad sp list --display-name "$servicePrincipalName" --query "[?displayName=='$servicePrincipalName'].displayName" -o tsv)
    if [ "$sp_match" != "$servicePrincipalName" ]; then
        echo "Error: Service Principal '$servicePrincipalName' does not match the expected value."
        yn="Y"
        #read -p "Do you want to create a new Service Principal (y/n)? " yn
        case $yn in
            [Yy]* ) automatic_sp_operations "create_new_sp";;
            [Nn]* ) automatic_sp_operations "enter_new_sp";;
            * ) echo "Please answer yes or no."; exit 1;;
        esac
    fi

    # Check if the resource group exists and matches the given name
    local rg_match=$(az group show --name "$Secrets_rg" --query "name" -o tsv)
    if [ "$rg_match" != "$Secrets_rg" ]; then
        echo "Error: Resource Group '$Secrets_rg' does not match the expected value."
        read -p "Do you want to create the Resource Group (y/n)? " yn
        #yn="Y"
        case $yn in
            [Yy]* ) read -p az group create --name "$Secrets_rg" --location "$RG_REGION";;
            [Nn]* ) echo "Resource Group creation skipped."; exit 1;;
            * ) echo "Please answer yes or no."; exit 1;;
        esac
    fi

    # Check if the key vault exists within the resource group and matches the given name
    local kv_match=$(az keyvault list --resource-group "$Secrets_rg" --query "[?name=='$KEY_VAULT_NAME'].name" -o tsv)
    if [ "$kv_match" != "$KEY_VAULT_NAME" ]; then
        echo "Error: Key Vault '$KEY_VAULT_NAME' does not match the expected value in Resource Group '$Secrets_rg'."
        read -p "Do you want to create the Key Vault (y/n)? " yn
        case $yn in
            [Yy]* ) az keyvault create --name "$KEY_VAULT_NAME" --resource-group "$Secrets_rg" --location "$RG_LOCATION";;
            [Nn]* ) echo "Key Vault creation skipped."; exit 1;;
            * ) echo "Please answer yes or no."; exit 1;;
        esac
    fi

    echo "Confirmed: Service Principal, Resource Group, and Key Vault names match the expected values on Azure."
}

# Function to delete Azure resources
function delete_aks_resources() {
  # Warn the user about the irreversible action of deleting resources.
  echo "WARNING: This will permanently delete the AKS cluster, Key Vault and resource group."
  
  # Prompt for user confirmation before proceeding.
  read -p "Are you sure you want to continue? There is NO undo! [yes/no]: " confirm_delete
  
  if [[ $confirm_delete =~ ^[Yy] ]]; then
    # Retrieve the resource group name from Terraform outputs
    local RESSOURCE_GROUP_NAME=$(terraform output -raw aks_resource_group_name)
    # Check if the RESSOURCE_GROUP_NAME variable is set
    if [ -z "$RESSOURCE_GROUP_NAME" ]; then
        echo "Error: Unable to retrieve the resource group name from Terraform outputs."
        exit 1
    fi
    # Retrieve the AKS cluster name from the resource group
    local AKS_CLUSTER_NAME=$(az aks list --resource-group $RESSOURCE_GROUP_NAME --query "[].name" -o tsv)

    # Delete the AKS cluster
    echo "Deleting the AKS cluster ($AKS_CLUSTER_NAME)..."
    az aks delete --name $AKS_CLUSTER_NAME --resource-group $RESSOURCE_GROUP_NAME --yes --no-wait

    # Delete the Key Vault after explaining its purpose
    echo "The Azure Key Vault ($KEY_VAULT_NAME) stores secrets and cryptographic keys securely. Deleting it will remove all stored items permanently."
    read -p "Are you sure you want to delete the Key Vault? This action cannot be undone. [yes/no]: " confirm_kv_delete

    if [[ $confirm_kv_delete =~ ^[Yy] ]]; then
      echo "Proceeding with deletion of the Key Vault ($KEY_VAULT_NAME)..."
      az keyvault delete --name "$KEY_VAULT_NAME" --resource-group "$Secrets_rg"
      echo "Key Vault deletion initiated..."
    else
      echo "Key Vault deletion cancelled by user."
    fi
    # Delete the resource group
    echo "Deleting the resource group ($RESSOURCE_GROUP_NAME)..."
    az group delete --name $RESSOURCE_GROUP_NAME --yes --no-wait

    echo "The AKS cluster, Key Vault, and resource group have been deleted."
  else
    echo "Resource deletion cancelled by user."
  fi
}


