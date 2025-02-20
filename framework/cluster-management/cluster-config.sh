#!/bin/bash
# cluster-config.sh: Cluster configuration variables for specific environment
# USEAGE: cluster-config.sh <terraform environment> <kubernetes environment>

# Define the list of environments for which to create overlays i.e ("Testing" "Production")
export PROJECT_ENVIRONMENTS=("testing" "staging" "production")
# Tag info
export TF_VAT_Project="neogenomics"
export TF_VAR_Owner="NeoGenomics"
export TF_VAT_Location="uksouth"
# Prerequisite for Terraform cluster creation 
export servicePrincipalName="NeoGenomicsTempMyWebApp"  # Service principal name
export Secrets_rg="secrets-rg"                         # Resource group for credential storage vault
export RG_LOCATION="UK South"
export KEY_VAULT_NAME="NeogenomicsTempKeyVault"        # Key Vault for storing secrets
export AKS_CLUSTER_NAME="aks-cluster-neogenomics"      # AKS cluster name
export tfplan_prefix="tfplan-aks-webapp"               # Prefix for naming Terraform plan files
export public_ip=$(curl -s ifconfig.me) 



# Framework Structure definitions
export SCRIPTS_DIR="$PROJECT_ROOT/framework"
export PROJECT_SETUP_DIR="$SCRIPTS_DIR/project-setup/$TF_VAT_Project"
# Terraform configuration directories
export TF_ENV_DIR="$PROJECT_ROOT/terraform"
export TF_PLANS_DIR="$TF_ENV_DIR/.plans"
export TF_MODULES_DIR="$TF_ENV_DIR/modules"
export TF_NETWORK_MODULE_FILES_DIR="$TF_MODULES_DIR/network"
export TF_AKS_MODULE_FILES_DIR="$TF_MODULES_DIR/aks"
# Kubernetes configuration directories.
export K8S_DIR="$PROJECT_ROOT/kubernetes"
export BASE_DIR="$K8S_DIR/base"
export OVERLAYS_DIR="$K8S_DIR/overlays"



# Additional variables that may be needed for Docker and Kubernetes configurations
export DOCKER_HUB_CONNECTION_NAME="dockerHubServiceConnection" # Replace with actual service connection name
export AKS_SERVICE_CONNECTION_NAME="aksServiceConnection" # Replace with actual service connection name
export DOCKER_HUB_TOKEN="your-docker-hub-token" # Replace with actual Docker Hub token
export IMAGE_NAME="myImageName" # Replace with actual image name
export TAG="latest" # Replace with actual tag
export MANIFESTS_PATH=$KUBERNETES_MANIFESTS_DIR # Replace with actual manifests path
export KUBERNETES_MANIFEST="$MANIFESTS_PATH/$KN_ENV/application-manifest.yaml" # Replace with actual manifest file name

# Source Scripts for Automation
source "$SCRIPTS_DIR/utilities/azure.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/azure.sh"; exit 1; }
source "$SCRIPTS_DIR/utilities/terraform.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/terraform.sh"; exit 1; }
source "$SCRIPTS_DIR/utilities/kubernetes.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/kubernetes.sh"; exit 1; }

# Create directories and set ownership.
{
  mkdir -p "$TF_ENV_DIR" && chown "$(whoami)":"$(whoami)" "$TF_ENV_DIR"
  mkdir -p "$TF_AKS_MODULE_FILES_DIR" && chown "$(whoami)":"$(whoami)" "$TF_AKS_MODULE_FILES_DIR"
  mkdir -p "$TF_NETWORK_MODULE_FILES_DIR" && chown "$(whoami)":"$(whoami)" "$TF_NETWORK_MODULE_FILES_DIR"
  mkdir -p "$BASE_DIR" && chown "$(whoami)":"$(whoami)" "$BASE_DIR"
  mkdir -p "$OVERLAYS_DIR" && chown "$(whoami)":"$(whoami)" "$OVERLAYS_DIR"
  mkdir -p "$TF_PLANS_DIR" && chown "$(whoami)":"$(whoami)" "$TF_PLANS_DIR"
} || { echo "Failed to create directories or change ownership"; exit 1; }