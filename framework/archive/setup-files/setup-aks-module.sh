#!/bin/bash

: <<'END_COMMENT'
This script generates the main.tf, variables.tf, and outputs.tf files for the AKS cluster module based on the specified environment. It is designed to be run within the env-setup directory of the AiCoreDevOpsCapstone project.

The script creates:
- main.tf with the resource definitions for the AKS cluster.
- variables.tf with variable declarations used in main.tf.
- outputs.tf with output values that provide information about the provisioned resources.

Additionally, it generates a terraform.tfvars file with environment-specific variable values that should be customized to define the infrastructure for that environment.

To run this script, follow these steps:
1. Navigate to the env-setup directory inside the terraform main module path.
2. Save this script as setup-aks-cluster.sh.
3. Give execute permissions to the script: chmod +x setup-aks-cluster.sh
4. Run the script with an environment name: ./setup-aks-cluster.sh <environment>
END_COMMENT

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
ENVIRONMENTS_DIR="${TF_ENV_DIR:?}/$ENVIRONMENT"
AKS_MODULE_DIR="$ENVIRONMENTS_DIR/modules/aks"
#AKS_RESOURCE_GROUP="${TF_VAR_aks_resource_group_name:?}"

# Create AKS_MODULE_DIR if it doesn't exist
if [ ! -d "$AKS_MODULE_DIR" ]; then
  mkdir -p "$AKS_MODULE_DIR" || { echo "Failed to create $AKS_MODULE_DIR"; exit 1; }
  chown "$(whoami)":"$(whoami)" "$AKS_MODULE_DIR"  # Set ownership of the directory
fi

# Create ENVIRONMENTS_DIR if it doesn't exist
if [ ! -d "$ENVIRONMENTS_DIR" ]; then
  mkdir -p "$ENVIRONMENTS_DIR"
  chown "$(whoami)":"$(whoami)" "$ENVIRONMENTS_DIR"  # Set ownership of the directory
fi

# Define the heredoc content for main.tf for the AKS cluster module as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

resource "azurerm_resource_group" "aks_rg" {
  name     = var.aks_resource_group_name
  location = var.aks_resource_group_location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.cluster_location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name           = "base"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
  }

  tags = {
    Environment = "Production"
  }
}
EOF

# Define the heredoc content for variables.tf for the AKS cluster module as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

variable "aks_cluster_name" {
  description = "The name of the AKS cluster to be created."
  type        = string
  default     = "my-flask-webapp-$ENVIRONMENT-cluster"
}

variable "kubernetes_version" {
  description = "The desired Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.26.6"
}

variable "service_principal_client_id" {
  description = "The Client ID for the service principal associated with the AKS cluster."
  type        = string
}

variable "service_principal_client_secret" {
  description = "The Client Secret for the service principal associated with the AKS cluster."
  type        = string
  sensitive   = true
}

# Note: aks_cluster_id and aks_kubeconfig are output values rather than input variables.
# They are defined in the outputs.tf file of the module.

# If you still want to define them as input variables (which is unusual), you can do so like this:

variable "aks_cluster_id" {
  description = "The ID of the provisioned AKS cluster."
  type        = string
}

variable "aks_kubeconfig" {
  description = "The kubeconfig content for accessing the provisioned AKS cluster."
  type        = string
  sensitive   = true
}

variable "cluster_location" {
  description = "The Azure region where the AKS cluster will be deployed."
  type        = string
  default     = "UK South"
}

variable "aks_resource_group_name" {
  description = "The name of the Resource Group where AKS resources will be deployed."
  type        = string
  default     = "aks-cluster-rg-$ENVIRONMENT"
}

variable "aks_resource_group_location" {
  description = "The Azure region where AKS resources will be deployed."
  type        = string
  default     = "UK South"
}

variable "dns_prefix" {
  description = "The DNS prefix of the cluster."
  type        = string
  default     = "aicoretemp-$ENVIRONMENT"
}
EOF

# Define the heredoc content for outputs.tf for the AKS cluster module as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

output "aks_cluster_name_env" {
  description = "The name of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id_env" {
  description = "The ID of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kubeconfig_env" {
  description = "The Kubernetes configuration file of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_resource_group_name_env" {
  description = "The name of the Azure Resource Group where the AKS resources were provisioned"
  value       = azurerm_resource_group.aks_rg.name
}

output "dns_prefix_env" {
  description = "The DNS prefix used for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.dns_prefix
}
EOF

# Define the heredoc content for terraform.tfvars for the AKS cluster module as a string
read -r -d '' tfvars_content <<EOF || true
# AKS Cluster Module Variables
EOF

# Call the function to create the files with the provided content
create_config_file "$AKS_MODULE_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $AKS_MODULE_DIR/main.tf"; exit 1; }
create_config_file "$AKS_MODULE_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $AKS_MODULE_DIR/variables.tf"; exit 1; }
create_config_file "$AKS_MODULE_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $AKS_MODULE_DIR/outputs.tf"; exit 1; }
create_config_file "$AKS_MODULE_DIR" "terraform.tfvars" "$tfvars_content" || { echo "Failed to create $AKS_MODULE_DIR/terraform.tfvars"; exit 1; }

