#!/bin/bash
# Cluster configuration variables for specific environment
# USEAGE: cluster-config.sh <terraform environment> <kubernetes environment>
TF_ENV=${1:-"dev"}

# Prerequisite for cluster creation 
TF_Infra_Scripts="tf-env-setup"                 # Directory for infrastructure provisioning scripts
K8S_Infra_Scripts="tf-k8s-setup"                # Directory for kubernetes provisioning scripts
servicePrincipalName="AiCoreTempMyFlaskWebApp"  # Service principal name
Secrets_rg="secrets-rg"                         # Resource group for credential storage vault
KEY_VAULT_NAME="AiCoreTempKeyVault2"            # Key Vault for storing secrets
AKS_CLUSTER_NAME="aicoretemp-aks-cluster"       # AKS cluster name
tfplan_prefix="tfplan-aks-webapp"               # Prefix for naming Terraform plan files
public_ip=$(curl -s ifconfig.me) 



# Common variables (non-environment-specific)
export AZURE_DEVOPS_SCRIPTS_DIR=$PROJECT_ROOT/azure-devops/shell
export AZURE_DEVOPS_CONFIG_DIR=$AZURE_DEVOPS_SCRIPTS_DIR/conf
export KUBERNETES_DIR=$PROJECT_ROOT/kubernetes
export KUBERNETES_BASE_DIR=$PROJECT_ROOT/kubernetes/base
export K8S_OVERLAYS_DIR=$KUBERNETES_DIR/overlays
export TF_ENV_DIR=$PROJECT_ROOT/terraform/environments

# Environment-specific variables (TF_ENV)
export TF_ENV_FILES_DIR="$TF_ENV_DIR/$TF_ENV"
export TF_SETUP_DIR=$AZURE_DEVOPS_SCRIPTS_DIR/$TF_Infra_Scripts
export TF_PLANS_DIR=$TF_ENV_FILES_DIR/.plans
export TF_MODULES_DIR=$TF_ENV_FILES_DIR/modules
export TF_NETWORK_MODULE_FILES_DIR=$TF_MODULES_DIR/network
export TF_AKS_MODULE_FILES_DIR=$TF_MODULES_DIR/aks

# Environment-specific variables (K8S_ENV)
export K8S_SETUP_DIR=$AZURE_DEVOPS_SCRIPTS_DIR/$K8S_Infra_Scripts
export K8S_FILES_DIR="${K8S_OVERLAYS_DIR:?}/$K8S_ENV"


# Additional variables that may be needed for Docker and Kubernetes configurations
export DOCKER_HUB_CONNECTION_NAME="dockerHubServiceConnection" # Replace with actual service connection name
export AKS_SERVICE_CONNECTION_NAME="aksServiceConnection" # Replace with actual service connection name
export DOCKER_HUB_TOKEN="your-docker-hub-token" # Replace with actual Docker Hub token
export IMAGE_NAME="myImageName" # Replace with actual image name
export TAG="latest" # Replace with actual tag
export MANIFESTS_PATH=$KUBERNETES_MANIFESTS_DIR # Replace with actual manifests path
export KUBERNETES_MANIFEST="$MANIFESTS_PATH/$KN_ENV/application-manifest.yaml" # Replace with actual manifest file name

# Source Scripts for Automation
source "$AZURE_DEVOPS_SCRIPTS_DIR/util/azure.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/util/azure.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/util/terraform.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/util/terraform.sh"; exit 1; }
source "$AZURE_DEVOPS_SCRIPTS_DIR/util/kubernetes.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/util/kubernetes.sh"; exit 1; }

# Create ENVIRONMENTS_DIR if it doesn't exist
if [ ! -d "$TF_ENV_FILES_DIR" ]; then
  mkdir -p "$TF_ENV_FILES_DIR"
  chown "$(whoami)":"$(whoami)" "$TF_ENV_FILES_DIR"  # Set ownership of the directory
fi

# Create Terraform MODULE_FILES_DIR if it doesn't exist
if [ ! -d "$TF_AKS_MODULE_FILES_DIR" ]; then
  mkdir -p "$TF_AKS_MODULE_FILES_DIR" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR"; exit 1; }
  chown "$(whoami)":"$(whoami)" "$TF_AKS_MODULE_FILES_DIR"  # Set ownership of the directory
fi

# Create TF_NETWORK_MODULE_DIR if it doesn't exist
if [ ! -d "$TF_NETWORK_MODULE_FILES_DIR" ]; then
  mkdir -p "$TF_NETWORK_MODULE_FILES_DIR"
  chown "$(whoami)":"$(whoami)" "$TF_NETWORK_MODULE_DIR"  # Set ownership of the directory
fi

# Create K8S_FILES_DIR if it doesn't exist
if [ ! -d "$K8S_FILES_DIR" ]; then
  mkdir -p "$K8S_FILES_DIR" || { echo "Failed to create $K8S_FILES_DIR"; exit 1; }
  chown "$(whoami)" "$K8S_FILES_DIR" || { echo "Failed to change ownership of $K8S_FILES_DIR"; exit 1; }
fi
