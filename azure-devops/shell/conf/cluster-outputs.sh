# Define the directory containing your Terraform configuration and state files
TF_ENV_DIR=$PROJECT_ROOT/terraform/environments

# Navigate to the Terraform environment directory if it exists, otherwise print an error message and exit
[ -d "$TF_ENV_DIR/$TF_ENV" ] && pushd "$TF_ENV_DIR/$TF_ENV" > /dev/null || { echo "Creating a new environment: '$TF_ENV'..."; return 0; }
# Fetch the outputs from Terraform and export them

# Networking configuration
export VNET_ADDRESS_SPACE=$(terraform output -raw vnet_address_space_output) || { echo "Failed to fetch VNET address space"; exit 1; }
export NETWORK_RESOURCE_GROUP_NAME=$(terraform output -raw network_resource_group_name_output) || { echo "Failed to fetch network resource group name"; exit 1; }

# Azure Kubernetes Cluster Configuration
export CURRENT_AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name) || { echo "Failed to fetch AKS cluster name"; exit 1; }
export CONTROL_PLANE_SUBNET_ADDRESS=$(terraform output -raw control_plane_subnet_address_output) || { echo "Failed to fetch control plane subnet address"; exit 1; }
export WORKER_NODE_SUBNET_ADDRESS=$(terraform output -raw worker_node_subnet_address_output) || { echo "Failed to fetch worker node subnet address"; exit 1; }
export KUBE_APISERVER_RULE_PORT=$(terraform output -raw kube_apiserver_rule_port_output) || { echo "Failed to fetch kube-apiserver rule port"; exit 1; }
export SSH_RULE_PORT=$(terraform output -raw ssh_rule_port_output) || { echo "Failed to fetch SSH rule port"; exit 1; }

# Return to the original directory
popd > /dev/null