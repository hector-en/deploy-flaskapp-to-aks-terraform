# cluster-output.sh
# Define the directory containing your Terraform configuration and state files
TF_ENV_DIR=$PROJECT_ROOT/terraform

# Navigate to the Terraform environment directory if it exists, otherwise print an error message and exit
[ -d "$TF_ENV_DIR" ] && pushd "$TF_ENV_DIR" > /dev/null || { echo "Creating a new environment: '..."; mkdir -p "$TF_ENV_DIR" && pushd "$TF_ENV_DIR" > /dev/null; }

# Fetch the outputs from Terraform and export them

# Fetch AKS configuration from Terraform outputs using JSON format
export AKS_RESOURCE_GROUP_NAME=$(terraform output -json | jq -r '.aks_cluster_details.value.resource_group_name') || { echo "Failed to fetch AKS resource group name"; exit 1; }
export NETWORK_RESOURCE_GROUP_NAME=$(terraform output -json | jq -r '.network_details.value.resource_group_name') || { echo "Failed to fetch network resource group name"; exit 1; }
export CURRENT_AKS_CLUSTER_NAME=$(terraform output -json | jq -r '.aks_cluster_details.value.name') || { echo "Failed to fetch AKS cluster name"; exit 1; }
export VNET_ADDRESS_SPACE=$(terraform output -json | jq -r '.network_details.value.vnet.address_space[]') || { echo "Failed to fetch VNet address space"; exit 1; }

# Networking configuration - Fetch details from Azure using Azure CLI
export VNET_ID=$(az network vnet list --resource-group "$NETWORK_RESOURCE_GROUP_NAME" --query "[0].id" -o tsv) || { echo "Failed to fetch VNet ID"; exit 1; }
export CONTROL_PLANE_SUBNET_ID=$(az network vnet subnet list --resource-group "$NETWORK_RESOURCE_GROUP_NAME" --vnet-name "$(basename $VNET_ID)" --query "[?contains(name, 'control-plane')].id" -o tsv) || { echo "Failed to fetch control plane subnet ID"; exit 1; }
export WORKER_NODE_SUBNET_ID=$(az network vnet subnet list --resource-group "$NETWORK_RESOURCE_GROUP_NAME" --vnet-name "$(basename $VNET_ID)" --query "[?contains(name, 'worker-node')].id" -o tsv) || { echo "Failed to fetch worker node subnet ID"; exit 1; }
export NETWORK_AKS_NSG_ID=$(az network nsg list --resource-group "$NETWORK_RESOURCE_GROUP_NAME" --query "[0].id" -o tsv) || { echo "Failed to fetch Network Security Group ID"; exit 1; }

# Fetch VNet address space directly from Terraform output
# Return to the original directory
popd > /dev/null