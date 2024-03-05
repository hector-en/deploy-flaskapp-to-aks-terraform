#terraform.sh:
# Source Terraform Libraries
source "$SCRIPTS_DIR/libraries/error-handler.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/error-handler.sh"; exit 1; }
source "$SCRIPTS_DIR/libraries/terraform_commands.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/terraform_commands.sh"; exit 1; }
source "$SCRIPTS_DIR/libraries/dialog-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/dialog-utilities.sh"; exit 1; }
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/file-utilities.sh"; exit 1; }
# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Function to run all .sh files in the Setup_dir
function run_setup_scripts() {
  # Navigate to the Setup_dir directory and execute all .sh scripts
  pushd "$PROJECT_SETUP_DIR" > /dev/null || { echo "Failed to navigate to $PROJECT_SETUP_DIR directory"; exit 1; }
  echo "Running setup scripts ..."
  for script in ./*.sh; do
    if [[ -x "$script" ]]; then
      if ! perform_operation_with_retry "$script"; then exit 1; fi
    else
      echo "Skipping non-executable script: $script"
    fi
  done
  echo "All setup scripts have been executed successfully."
  echo "-----------------------------------------------------------------------"
  echo "Terraform folder: '$TF_ENV_DIR'"
  echo "Kubernetes folder: '$K8S_DIR'"
  echo "Plans folder: '$TF_PLANS_DIR'"
  echo "----------------------------------------------------------------------------------"
  popd > /dev/null  # Return to the original directory after all operations
}

# Function to delete AKS resources
function delete_aks_resources() {
  # Source the outputs from Terraform to get AKS cluster and resource group names.
source "$PROJECT_ROOT/framework/cluster-management/cluster-output.sh" || {
  echo -e "${RED}Failed to source cluster-output.sh${NC}"
  exit 1
}

  # Retrieve the resource group name from Terraform outputs
  local resourceGroupName=$AKS_RESOURCE_GROUP_NAME
  
  # Check if the resourceGroupName variable is set
  if [ -z "$resourceGroupName" ]; then
      echo "Error: Unable to retrieve the resource group name from Terraform outputs."
      exit 1
  fi
  

  # Check if the AKS cluster name is retrieved
  if [ -z "$CURRENT_AKS_CLUSTER_NAME" ]; then
      echo "Error: Unable to retrieve the AKS cluster name from the resource group."
      exit 1
  fi

  # Delete the AKS cluster
  echo "Deleting the AKS cluster ($CURRENT_AKS_CLUSTER_NAME) in resource group ($AKS_RESOURCE_GROUP_NAME)..."
  az aks delete --name $CURRENT_AKS_CLUSTER_NAME --resource-group $AKS_RESOURCE_GROUP_NAME --yes --no-wait

  # Uncomment the following lines if you want to delete the Key Vault as well
  # echo "Deleting the Key Vault ($KEY_VAULT_NAME) in resource group ($resourceGroupName)..."
  # az keyvault delete --name $KEY_VAULT_NAME --resource-group $resourceGroupName

  # Delete the resource group
  echo "Deleting the resource group ($AKS_RESOURCE_GROUP_NAME)..."
  az group delete --name $AKS_RESOURCE_GROUP_NAME --yes --no-wait

  # Delete the resource group
  echo "Deleting the resource group ($NETWORK_RESOURCE_GROUP_NAME)..."
  az group delete --name $NETWORK_RESOURCE_GROUP_NAME --yes --no-wait
}

# Orchestrates the Terraform init, plan, and apply sequence, and verifies the AKS cluster if successful.
function terraform_init() {
echo "Initiating Terraform command execution..."

  # Set dynamic variables
  export TF_VAR_public_ip=$(curl -s ifconfig.me)

  # Initialize Terraform
  if ! perform_operation_with_retry "terraform init"; then 
    echo "Terraform initialization failed. Cannot proceed to planning phase."
    popd > /dev/null  # Return to the original directory
    return 1
  fi
  echo "----------------------------------------------------------------------------"
}

function terraform_plan() {
  ENVIRONMENT=$1
  ROLLOUT=$2
  # Create a Terraform plan
  if ! terraform_plan_full $ENVIRONMENT; then
    echo "Terraform planning failed. Cannot proceed to apply phase."
    #popd > /dev/null  # Return to the original directory
    return 1
  fi
  echo "----------------------------------------------------------------------------"
  #]popd > /dev/null  # Return to the original directory after all operations
  confirm_plan_apply $ROLLOUT
  if [ $? -eq 1 ]; then # 1 (fail)
    return 1  # Signal to retry the apply with a new plan
  else
    :
  fi
}

# Function to apply a Terraform plan and handle errors using the handle_terraform_errors function.
# USAGE: apply_terraform_plan "your_plan_file_name_here"
# Function to apply a Terraform plan and handle errors with retry and exponential backoff.

# Function to apply a Terraform plan and handle errors with retry logic.
function apply_terraform_plan_and_handle_errors() {
  local plan_filename=$1
  local vars=$2
  local max_attempts=1
  local attempt_delay=5
  local terraform_output
  local exit_code

  # Loop until there are no actionable errors
  while true; do
    # Use perform_operation_with_retry to attempt the Terraform apply with retries
    if ! perform_operation_with_retry "terraform apply $plan_filename " $max_attempts; then
      echo -e "${RED}Error applying Terraform plan. Attempting to resolve...${NC}"

      # If the apply fails after retries, pass the last error output to handle_terraform_errors
      handle_terraform_errors <<< "$terraform_output"
      exit_code=$?

      # Check if handle_terraform_errors resolved the issue (specific exit code 2)
      if [ "$exit_code" -eq 2 ]; then
        echo -e "${YELLOW}Retrying Terraform apply after handling errors...${NC}"
        # Reset attempt delay for a fresh set of retries
        attempt_delay=5
      else
        echo -e "${YELLOW}No actionable error was found or an unrecoverable error occurred, stopping apply...${NC}"
        return 1
      fi
    else
      echo -e "${GREEN}Terraform apply completed successfully.${NC}"
      return 0
    fi
  done
}

# Verifies AKS cluster existence and connectivity.
function verify_and_check_aks_cluster() {

  echo "Verifying AKS Cluster..."
  confirm_aks_cluster_creation
  # Source output variables from cluster-output.sh
  source "$SCRIPTS_DIR/cluster-management/cluster-output.sh" || { echo "Failed to source cluster-outputs.sh"; exit 1; }

  # Check if the resource group name variable is set
  if [ -z "$NETWORK_RESOURCE_GROUP_NAME" ]; then
    echo -e "${RED}Error: Unable to retrieve the network resource group name from Terraform outputs.${NC}"
    exit 1
  fi

  # Check if the AKS cluster name variable is set
  if [ -z "$CURRENT_AKS_CLUSTER_NAME" ]; then
    echo -e "${RED}Error: Unable to retrieve the AKS cluster name from Terraform outputs.${NC}"
    exit 1
  fi

  # Check if the AKS cluster exists in the specified resource group
  local aksClusterExists=$(az aks show --name "$CURRENT_AKS_CLUSTER_NAME" --resource-group "$AKS_RESOURCE_GROUP_NAME" --query "name" -o tsv 2>/dev/null)

  if [ -z "$aksClusterExists" ]; then
    echo "AKS cluster $CURRENT_AKS_CLUSTER_NAME under resource group $AKS_RESOURCE_GROUP_NAME does not exist."
    exit 1
  else
    echo "The AKS cluster $CURRENT_AKS_CLUSTER_NAME has been verified to exist."

    # Retrieve the kubeconfig file for the AKS cluster
    echo "Retrieving the kubeconfig file for the AKS cluster..."
    az aks get-credentials --resource-group "$AKS_RESOURCE_GROUP_NAME" --name "$CURRENT_AKS_CLUSTER_NAME" --overwrite-existing

    # Test the connection to the AKS cluster
    echo "Testing the connection to the AKS cluster..."
    if ! kubectl get nodes; then
      echo -e "${RED}Failed to connect to the AKS cluster $CURRENT_AKS_CLUSTER_NAME.${NC}"
      exit 1
    else
      echo -e "${GREEN}Successfully connected to the AKS cluster $CURRENT_AKS_CLUSTER_NAME.${NC}"
    fi
  fi
}

echo "Terraform functions are now available."