#!/bin/bash

# Filename: create-network-module.sh
# Purpose: Generates Terraform configs main.tf, variables.tf, and outputs.tf files for network resources deployment based on the specified environment. It is designed to be run within the env-setup directory.

# Source automation scripts
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/file-utilities.sh"; exit 1; }

# Define the heredoc content for main.tf as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

# Resource Group using the network_infrastructure variable.
resource "azurerm_resource_group" "rg" {
  name     = var.network_infrastructure.resource_group.name
  location = var.network_infrastructure.resource_group.location
  tags     = var.network_infrastructure.resource_group.tags
}

# Virtual Network creation using the network_infrastructure variable.
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_infrastructure.vnet.name
  resource_group_name = var.network_infrastructure.resource_group.name
  location            = var.network_infrastructure.resource_group.location
  address_space       = var.network_infrastructure.vnet.address_space
}

# Subnet creation for the control plane.
resource "azurerm_subnet" "control_plane_subnet" {
  name                 = var.network_infrastructure.subnets["control_plane_subnet"].name
  resource_group_name  = var.network_infrastructure.resource_group.name
  virtual_network_name = var.network_infrastructure.vnet.name
  address_prefixes     = var.network_infrastructure.subnets["control_plane_subnet"].address_prefixes
}

# Subnet creation for the worker nodes.
resource "azurerm_subnet" "worker_node_subnet" {
  name                 = var.network_infrastructure.subnets["worker_node_subnet"].name
  resource_group_name  = var.network_infrastructure.resource_group.name
  virtual_network_name = var.network_infrastructure.vnet.name
  address_prefixes     = var.network_infrastructure.subnets["worker_node_subnet"].address_prefixes
}

# Network Security Group creation using the network_infrastructure variable.
resource "azurerm_network_security_group" "nsg" {
  name                = var.network_infrastructure.nsg.name
  location            = var.network_infrastructure.resource_group.location
  resource_group_name = var.network_infrastructure.resource_group.name

  dynamic "security_rule" {
    for_each = var.network_infrastructure.nsg.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

# Networking Infrastructure Variable

# Combined configuration for Azure networking resources supporting the AKS cluster.
variable "network_infrastructure" {
  description = "Combined configuration for Azure networking resources."
  type = object({
    resource_group = object({
      name     = string
      location = string
      tags      = map(string)
    })
    vnet = object({
      name           = string
      address_space  = list(string)
    })
    subnets = map(object({
      name            = string
      address_prefixes = list(string)
    }))
    nsg = object({
      name             = string
      security_rules   = list(map(any))
    })
  })
  # Default values provide a template for network infrastructure, ensuring essential components like VNet and subnets are predefined.
  default = {
    resource_group = {
      name     = "network-rg"
      location = "UK South"
      tags     = {}
    }
    vnet = {
      name           = "aks-vnet"
      address_space  = ["10.10.0.0/16"]
    }
    subnets = {
      control_plane_subnet = {
        name            = "control-plane-subnet"
        address_prefixes = ["10.10.1.0/24"]
      },
      worker_node_subnet = {
        name            = "worker-node-subnet"
        address_prefixes = ["10.10.2.0/24"]
      }
    }
    nsg = {
      name = "aks-nsg"
      security_rules = [
        {
          name                       = "kube-apiserver-rule",
          priority                   = 1001,
          direction                  = "Inbound",
          access                     = "Allow",
          protocol                   = "Tcp",
          source_port_range          = "*",
          destination_port_range     = "6443",
          source_address_prefix      = "Internet",
          destination_address_prefix = "*"
        },
        {
          name                       = "ssh-rule",
          priority                   = 1002,
          direction                  = "Inbound",
          access                     = "Allow",
          protocol                   = "Tcp",
          source_port_range          = "*",
          destination_port_range     = "22",
          source_address_prefix      = "Internet",
          destination_address_prefix = "*"
        }
      // Additional security rules can be added here as needed.
      ]
    }
  }
}
EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

# outputs.tf in the network module

output "network_details" {
  description = "Consolidated details of the networking resources."
  value = {
    resource_group_name = azurerm_resource_group.rg.name
    vnet = {
      id            = azurerm_virtual_network.vnet.id
      address_space = azurerm_virtual_network.vnet.address_space
    }
    subnets = {
      control_plane_subnet = azurerm_subnet.control_plane_subnet.id
      worker_node_subnet   = azurerm_subnet.worker_node_subnet.id
    }
    nsg_id = azurerm_network_security_group.nsg.id
  }
}
EOF



# Call the function to create the main.tf file with the provided content
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/main.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/variables.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_FILES_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_FILES_DIR/outputs.tf"; exit 1; }

