#!/bin/bash 

: <<'COMMENT_BLOCK'
Itt appends necessary resources to the existing main.tf file in the networking-module directory for an AKS cluster.

The task was to define essential networking resources within the main.tf configuration file of the networking-module. This includes creating a Virtual Network (VNet), two subnets for the control plane and worker nodes, and a Network Security Group (NSG) with two inbound rules.

To run this script, follow these steps:

1. Save this script as solution_issue07.sh in the config directory in the aks-terraform main module path.
2. Give execute permissions to the script: chmod +x solution_issue07.sh
3. Run the script: ./solution_issue07.sh
`.
COMMENT_BLOCK

NETWORKING_MODULE_DIR="networking-module"

# Get public IP address
public_ip=$(curl -s ifconfig.me)

# Append resources to main.tf in networking-module
cat << EOF >> $NETWORKING_MODULE_DIR/main.tf
# This script was created by solution-issue07.sh.

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
# Print a success message
echo "$NETWORKING_MODULE_DIR/main.tf has been successfully created with the necessary input variables."

