#!/bin/bash

# Filename: setup-root-configuration.sh
# Purpose: Generates root Terraform configuration files for AKS and network deployment.

# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  echo "Usage: $0 <environment>"
  exit 1
fi

# Source automation scripts
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/utilities/setupfiles.sh"; exit 1; }

# Define the heredoc content for main.tf as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

# This block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # This will get the latest compatible version after 3.0.0
    }
  }
}

# This block defines the Azure provider and uses the input variables defined above for authentication.
provider "azurerm" {
  features {}

  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
  subscription_id = var.subscription_id
}

# This block imports the network module and provides values for the required input variables.
module "network" {
  source = "./modules/network"
}

# This block imports the AKS cluster module and provides values for the required input variables.
module "aks" {
  source = "./modules/aks"

  aks_cluster_name             = "aicoretemp-aks-cluster"
  dns_prefix                   = "aicoretemp"  # updated DNS prefix
  kubernetes_version           = "1.28.5" # latest non-preview (generally available) version for uksouth after 1.26.6
  #service_principal_client_id  = var.client_id
  #service_principal_secret     = var.client_secret
  #resource_group_name          = var.resource_group_name
  vnet_id                      = module.network.vnet_id
  control_plane_subnet_id      = module.network.control_plane_subnet_id
  worker_node_subnet_id        = module.network.worker_node_subnet_id
  aks_nsg_id                   = module.network.aks_nsg_id
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

# Input variable for the Client ID of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_id" {
  description = "The Client ID of the Azure Service Principal"
  type        = string
}

# Input variable for the Client Secret of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_secret" {
  description = "The Client Secret of the Azure Service Principal"
  type        = string
  sensitive   = true
}

# Input variable for the Tenant ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "tenant_id" {
  description = "The Tenant ID of the Azure account"
  type        = string
}

# Input variable for the Subscription ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "subscription_id" {
  description = "The Subscription ID of the Azure account"
  type        = string
}

EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

# Output for AKS cluster name from the aks_cluster module
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_cluster_name
}

# Outputs from the network module
output "network_vnet_id" {
  description = "The ID of the Virtual Network created by the network module"
  value       = module.network.vnet_id
}

output "network_control_plane_subnet_id" {
  description = "The ID of the control plane subnet created by the network module"
  value       = module.network.control_plane_subnet_id
}

output "network_worker_node_subnet_id" {
  description = "The ID of the worker node subnet created by the network module"
  value       = module.network.worker_node_subnet_id
}

output "network_aks_nsg_id" {
  description = "The ID of the Network Security Group created by the network module"
  value       = module.network.aks_nsg_id
}

output "resource_group_name" {
  description = "The name of the resource group where network resources are provisioned"
  value       = module.network.resource_group_name
}
EOF

# Call the function to create the terraform.tfvars file with the provided content
create_config_file "$TF_ENV_FILES_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_ENV_FILES_DIR/main.tf"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_ENV_FILES_DIR/variables.tf"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_ENV_FILES_DIR/outputs.tf"; exit 1; }
