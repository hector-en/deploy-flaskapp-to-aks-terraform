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
