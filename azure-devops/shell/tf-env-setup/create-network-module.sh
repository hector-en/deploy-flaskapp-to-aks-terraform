#!/bin/bash

# Filename: setup-network-module.sh
# Purpose: Generates Terraform configs main.tf, variables.tf, and outputs.tf files for network resources deployment based on the specified environment. It is designed to be run within the env-setup directory.

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
# This file was created by setup-network-module.sh for the network module.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "control_plane_subnet" {
  name                 = "control-plane-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "worker_node_subnet" {
  name                 = "worker-node-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "kube-apiserver-rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443" # default port for kube-apiserver
    source_address_prefix      = "$public_ip"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh-rule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "$public_ip"
    destination_address_prefix = "*"
  }
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

# This script was created by solution-issue06.sh

variable "resource_group_name" {
  description = "Represents the Resource Group where networking resources will be deployed."
  type        = string
  default     = "networking-rg"
}

variable "location" {
  description = "Specifies the Azure region where networking resources will be deployed."
  type        = string
  default     = "UK South"
}

variable "vnet_address_space" {
  description = "Defines the address space for the Virtual Network in the main configuration."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}
EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "control_plane_subnet_id" {
  description = "The ID of the control plane subnet within the VNet"
  value       = azurerm_subnet.control_plane_subnet.id
}

output "worker_node_subnet_id" {
  description = "The ID of the worker node subnet within the VNet"
  value       = azurerm_subnet.worker_node_subnet.id
}

output "resource_group_name" {
  description = "The name of the Azure Resource Group where the networking resources were provisioned"
  value       = azurerm_resource_group.rg.name
}

output "aks_nsg_id" {
  description = "The ID of the Network Security Group (NSG)"
  value       = azurerm_network_security_group.nsg.id
}
EOF

# Call the function to create the main.tf file with the provided content
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/main.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/variables.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/outputs.tf"; exit 1; }

