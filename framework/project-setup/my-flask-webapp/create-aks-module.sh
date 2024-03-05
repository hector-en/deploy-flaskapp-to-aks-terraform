#!/bin/bash

# Filename: create-aks-mudule.sh
# Purpose: Generates Terraform configuration files for the AKS cluster module.


# Source automation scripts
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/file-utilities.sh"; exit 1; }

# Define the heredoc content for main.tf for the AKS cluster module as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by create-aks-cluster.sh for the AKS cluster module.

resource "azurerm_resource_group" "rg" {
  name     = var.aks_config.resource_group_name
  location = var.aks_config.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_config.cluster_name
  location            = azurerm_resource_group.rg.location # Corrected typo 'locstion' to 'location'
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_config.dns_prefix
  tags                = var.aks_config.tags

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2_v2"
    vnet_subnet_id  = var.worker_node_subnet_id  # Corrected line
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = var.aks_network_profile.network_plugin
    network_policy = var.aks_network_profile.network_policy
    # Additional network profile attributes can be referenced here if defined.
  }
}
EOF

# Define the heredoc content for variables.tf for the AKS cluster module as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by create-aks-cluster.sh as Variable definitions for the AKS cluster module.

# variables.tf in the AKS module

# Defines core attributes of the AKS cluster like name and version, essential for cluster creation.
 variable "aks_config" {
  description = "Core configuration for the AKS cluster."
  type = object({
    cluster_name            = string
    location                = string
    resource_group_name     = string
    dns_prefix              = string
    kubernetes_version      = string
    tags                    = map(string)
  })
  # Default values for AKS cluster setup.
  default = {
    cluster_name            = "aks-cluster-aicoretemp"
    location                = "uksouth"
    resource_group_name     = "aks-rg"
    dns_prefix              = "aicoretemp"
    kubernetes_version      = "1.18.14"
    tags                    = {}
  }
}

# Specifies AKS network plugin and policy, key for cluster communication and security.
variable "aks_network_profile" {
  description = "Specifies network plugin and policy for AKS, impacting connectivity and security."
  type = object({
    network_plugin     = string
    network_policy     = string
  })
  # Default network profile specifies 'azure' plugin and 'calico' policy.
  default = {
    network_plugin = "azure"
    network_policy = "calico"
  }
}

# The ID of the Virtual Network (VNet).
# This value is used to connect the AKS cluster to the VNet.
variable "vnet_id" {
  description = "The ID of the Virtual Network (VNet)."
  type        = string
}

# The ID of the control plane subnet within the VNet.
# This value is used to specify the subnet where the control plane components of the AKS cluster will be deployed.
variable "control_plane_subnet_id" {
  description = "The ID of the control plane subnet within the VNet."
  type        = string
}

# The ID of the worker node subnet within the VNet.
# This value is used to specify the subnet where the worker nodes of the AKS cluster will be deployed.
variable "worker_node_subnet_id" {
  description = "The ID of the worker node subnet within the VNet."
  type        = string
}

# The ID of the Network Security Group (NSG).
# This value is used to associate the NSG with the AKS cluster for security rule enforcement and traffic filtering.
variable "aks_nsg_id" {
  description = "The ID of the Network Security Group (NSG)."
  type        = string
}
EOF

# Define the heredoc content for outputs.tf for the AKS cluster module as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by create-aks-cluster.sh for the AKS cluster module.

output "aks_cluster_details" {
  description = "Details of the provisioned AKS cluster."
  value = {
    name                = azurerm_kubernetes_cluster.aks.name
    id                  = azurerm_kubernetes_cluster.aks.id
    resource_group_name = azurerm_resource_group.rg.name
  }
  sensitive = false
}
EOF

# Call the function to create the files with the provided content
create_config_file "$TF_AKS_MODULE_FILES_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/main.tf"; exit 1; }
create_config_file "$TF_AKS_MODULE_FILES_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/variables.tf"; exit 1; }
create_config_file "$TF_AKS_MODULE_FILES_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/outputs.tf"; exit 1; }

