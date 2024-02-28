# Source Terraform Libraries
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_err_handler.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_err_handler.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_commands.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_commands.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_dialogs.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/lib/tf_dialogs.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh"; exit 1; }


# Function to check and install jq if not present
function ensure_jq_installed() {
  if ! command -v jq &> /dev/null; then
    echo "jq could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
    echo "jq has been installed successfully."
  else
    echo "jq is already installed."
  fi
}

# Function to check and install kubectl if not present
function ensure_kubectl_installed() {
  if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found, installing..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "kubectl has been installed successfully."
  else
    echo "kubectl is already installed."
  fi
}

# Function retrieves and sets Service Principal credentials as environment variables for Terraform.
function setup_env_vars() {
    # Call the function to confirm the resources match
    confirm_azure_resources_match || exit 1
    export_tenant_and_subscription_ids
    export_service_principal_credentials
    echo "Azure credentials have been set successfully."
    echo "----------------------------------------------------------------------------"
    echo "Client ID: $TF_VAR_client_id"
    if [ -z "$TF_VAR_client_secret" ]; then
        echo "Client Secret is not set or is empty."
    else
       :
    fi
    echo "----------------------------------------------------------------------------"
}

# Function to run all .sh files in the TF_Setup_dir
function run_setup_scripts() {
  # Navigate to the TF_Setup_dir directory and execute all .sh scripts
  pushd "$TF_SETUP_DIR" > /dev/null || { echo "Failed to navigate to $TF_SETUP_DIR directory"; exit 1; }
  echo "Running setup scripts ..."
  for script in ./*.sh; do
    if [[ -x "$script" ]]; then
      if ! perform_operation_with_retry "$script $TF_ENV"; then exit 1; fi
    else
      echo "Skipping non-executable script: $script"
    fi
  done
  echo "All setup scripts have been executed successfully."
  echo "-----------------------------------------------------------------------"
  echo "Terraform environment: '$TF_ENV' | Config path: '$TF_ENV_FILES_DIR'"
  echo "Kubernetes overlays: '$K8S_FILES_DIR'"
  echo "----------------------------------------------------------------------------------"
  popd > /dev/null  # Return to the original directory after all operations
}

# Function to delete AKS resources
function delete_aks_resources() {
  # Retrieve the resource group name from Terraform outputs
  local resourceGroupName=$(terraform output -raw aks_resource_group_name)
  
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
  echo "Deleting the AKS cluster ($aksClusterName) in resource group ($resourceGroupName)..."
  az aks delete --name $aksClusterName --resource-group $resourceGroupName --yes --no-wait

  # Uncomment the following lines if you want to delete the Key Vault as well
  # echo "Deleting the Key Vault ($KEY_VAULT_NAME) in resource group ($resourceGroupName)..."
  # az keyvault delete --name $KEY_VAULT_NAME --resource-group $resourceGroupName

  # Delete the resource group
  echo "Deleting the resource group ($resourceGroupName)..."
  az group delete --name $resourceGroupName --yes --no-wait

  echo "Deletion initiated for AKS cluster ($aksClusterName) and resource group ($resourceGroupName)."
}

# Orchestrates the Terraform init, plan, and apply sequence, and verifies the AKS cluster if successful.
function init_plan() {
echo "Initiating Terraform command execution..."
  # Navigate to the Terraform environment directory if it exists, otherwise print an error message and exit
  [ -d "$TF_ENV_DIR" ] && pushd "$TF_ENV_FILES_DIR" > /dev/null || { echo "The Terraform environment directory does not exist."; }

  # Set dynamic variables
  export TF_VAR_public_ip=$(curl -s ifconfig.me)

  # Initialize Terraform
  if ! perform_operation_with_retry "terraform init"; then 
    echo "Terraform initialization failed. Cannot proceed to planning phase."
    popd > /dev/null  # Return to the original directory
    return 1
  fi
  echo "----------------------------------------------------------------------------"

  # Create a Terraform plan
  if ! terraform_plan; then
    echo "Terraform planning failed. Cannot proceed to apply phase."
    popd > /dev/null  # Return to the original directory
    return 1
  fi
  echo "----------------------------------------------------------------------------"
  popd > /dev/null  # Return to the original directory after all operations
  confirm_plan_apply
  if [ $? -eq 1 ]; then # 1 (fail)
    return 1  # Signal to retry the apply with a new plan
  else
    :
  fi
}

# Function to apply a Terraform plan and handle errors using the handle_terraform_errors function.
# USAGE: apply_terraform_plan "your_plan_file_name_here"
function apply_terraform_plan_and_handle_errors() {
  local plan_filename=$1
  local exit_code=1
  local terraform_output
  local lock_id

  until [ "$exit_code" -eq 0 ]; do
    echo "Applying $plan_filename ..."

    # Check for a state lock before applying
    lock_id=$(terraform state list 2>&1 | grep -oP "(?<=ID: ).*")
    if [ -n "$lock_id" ]; then
      echo "Terraform state is locked by another process. Lock ID: $lock_id"
      echo "Attempting to unlock the state..."
      terraform force-unlock "$lock_id"
    fi

    # Run terraform apply, capturing both exit code and stderr
    terraform_output=$(terraform apply "$TF_PLANS_DIR/$plan_filename" 2>&1)
    exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
      echo "An error occurred during Terraform apply:"
      echo "$terraform_output"
      echo "Attempting to resolve..."

      # Call handle_terraform_errors with the captured stderr as input
      handle_terraform_errors <<< "${terraform_output}"
      
      # Update exit_code in case handle_terraform_errors resolved the issue
      exit_code=$?
      
      # Check if a retry is needed (specific exit code 2 from handle_terraform_errors)
      if [ "$exit_code" -eq 2 ]; then
        echo "Retrying Terraform apply after handling errors..."
        confirm_plan_apply
        # Check if confirm_plan_apply returned 1 (fail)
        if [ $? -eq 1 ]; then
        # Select a different plan or quit
          exit 1
        fi
        terraform apply "$TF_PLANS_DIR/$plan_filename"        
        # Reset exit_code to force another iteration of the loop
        exit_code=1
        continue  # Continue the loop to retry apply with the new plan
      else
        echo "No actionable error was found or an unrecoverable error occurred, stopping apply..."
        break
      fi
    else
      echo "Terraform apply completed successfully."
      echo "========================================"
      exit_code=0
    fi
  done
}

echo "Terraform functions are now available."