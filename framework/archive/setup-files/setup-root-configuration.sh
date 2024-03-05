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

# Creates a configuration file for Terraform or Kubernetes in the specified directory.
# Usage: create_configuration_file <directory> <filename> <heredoc-content>
function create_config_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Write the content to the file
  echo "$file_content" > "$file_path"

  # Check if the file was created successfully
  if [ ! -f "$file_path" ]; then
    echo "Failed to create ${file_name} at ${file_dir}"
    return 1
  else
    echo "${file_name} created successfully at ${file_dir}"
    return 0
  fi
}

# Appends provided content to a file in the specified directory, verifying successful operation.
append_to_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Check if the file exists before attempting to append
  if [ ! -f "$file_path" ]; then
    echo "File ${file_name} does not exist at ${file_dir}"
    return 1
  fi

  # Append the content to the file
  echo "$file_content" >> "$file_path"

  # Verify that the file still exists after appending
  if [ ! -f "$file_path" ]; then
    echo "Failed to append to ${file_name} at ${file_dir}"
    return 1
  else
    echo "Content appended successfully to ${file_name} at ${file_dir}"
    return 0
  fi
}


ENVIRONMENT=$1
ENVIRONMENTS_DIR="$TF_ENV_DIR/$ENVIRONMENT"
public_ip=$(curl -s ifconfig.me)

# Create directories if they don't exist
# Create ENVIRONMENTS_DIR if it doesn't exist
if [ ! -d "$ENVIRONMENTS_DIR" ]; then
  mkdir -p "$ENVIRONMENTS_DIR" || { echo "Failed to create $ENVIRONMENTS_DIR"; exit 1; }
  chown "$(whoami)":"$(whoami)" "$ENVIRONMENTS_DIR"  # Set ownership of the directory
fi

# Define the heredoc content for main.tf as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

module "network" {
  source = "./modules/network"

  network_resource_group_name_input   = "networking-rg-$ENVIRONMENT"
  vnet_address_space_output           = module.network.vnet_address_space
  vnet_id_output                      = module.network.vnet_id
  control_plane_subnet_id_output      = module.network.control_plane_subnet_id
  control_plane_subnet_address_output = module.network.control_plane_subnet_address
  worker_node_subnet_id_output        = module.network.worker_node_subnet_id
  worker_node_subnet_address_output   = module.network.worker_node_subnet_address
  aks_nsg_id_output                   = module.network.aks_nsg_id 
  kube_apiserver_rule_port_number     = "6443"
  ssh_rule_port_number                = "22"
 
}

module "aks" {
  source = "./modules/aks"

  #cluster_location                 = "Uk South"
  kubernetes_version               = "1.26.6"
  service_principal_client_id      = var.client_id
  service_principal_client_secret  = var.client_secret
  aks_cluster_name                 = "my-flask-webapp-$ENVIRONMENT-cluster"
  dns_prefix                       = "aicoretemp-$ENVIRONMENT"
  aks_cluster_id                   = module.aks.aks_cluster_id_env
  aks_resource_group_name          = "aks-cluster-rg-$ENVIRONMENT"
  aks_kubeconfig                   = module.aks.aks_kubeconfig_env
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

variable "client_id" {
  description = "The Client ID of the Azure Service Principal"
  type        = string
}

variable "client_secret" {
  description = "The Client Secret of the Azure Service Principal"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID of the Azure account"
  type        = string
}

variable "subscription_id" {
  description = "The Subscription ID of the Azure account"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod, staging)."
  type        = string
  default     = "$ENVIRONMENT"
}

variable "my_public_ip" {
  description = "Public IP address to whitelist for SSH and Kubernetes API server access."
  type        = string
}

# ...

EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by 05-setup-root-configuration.sh for the root module.

# Outputs from the network module
output "network_vnet_id" {
  description = "The ID of the Virtual Network created by the network module"
  value       = module.network.vnet_id
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network created by the networking module."
  value       = module.network.vnet_address_space
}

output "network_control_plane_subnet_id" {
  description = "The ID of the control plane subnet created by the network module"
  value       = module.network.control_plane_subnet_id
}

output "worker_node_subnet_id" {
  description = "The ID of the worker node subnet created by the network module"
  value       = module.network.worker_node_subnet_id
}

output "control_plane_subnet_address" {
  description = "The address prefixes of the control plane subnet created by the networking module."
  value       = module.network.control_plane_subnet_address
}


output "network_aks_nsg_id" {
  description = "The ID of the Network Security Group created by the network module"
  value       = module.network.aks_nsg_id
}

output "network_resource_group_name" {
  description = "The name of the resource group where network resources are provisioned"
  value       = module.network.network_resource_group_name_env
}

output "aks_resource_group_name" {
  description = "The name of the resource group where network resources are provisioned"
  value       = module.aks.aks_resource_group_name_env
}


# Outputs from the aks_cluster module
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_cluster_name_env
}


# Add other outputs as needed
# ...
EOF

# Define the heredoc content for terraform.tfvars as a string
read -r -d '' tfvars_content <<EOF || true
# Environment-specific variables for the $ENVIRONMENT environment.

my_public_ip = "$public_ip"          # Dynamically set public IP address.


# Add other variables as needed
EOF

# Call the function to create the terraform.tfvars file with the provided content
create_config_file "$ENVIRONMENTS_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $ENVIRONMENTS_DIR/main.tf"; exit 1; }
create_config_file "$ENVIRONMENTS_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $ENVIRONMENTS_DIR/variables.tf"; exit 1; }
create_config_file "$ENVIRONMENTS_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $ENVIRONMENTS_DIR/outputs.tf"; exit 1; }
create_config_file "$ENVIRONMENTS_DIR" "terraform.tfvars" "$tfvars_content" || { echo "Failed to create $ENVIRONMENTS_DIR/terraform.tfvars"; exit 1; }
