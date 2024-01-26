resource "azurerm_resource_group" "rg" {
# This resource block creates the resource group for networking resources in Azure.
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_virtual_network" "vnet" {
# This resource block creates a Virtual Network in Azure.
  name                = "aks-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "control_plane_subnet" {
# This resource block creates a subnet for the control plane of the AKS cluster.
  name                 = "control-plane-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "worker_node_subnet" {
# This resource block creates a subnet for the worker nodes of the AKS cluster.
  name                 = "worker-node-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
# This resource block creates a Network Security Group for controlling access to the AKS cluster.
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
# This security rule allows inbound traffic to the kube-apiserver from a specific IP address.
    name                       = "kube-apiserver-rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443" # default port for kube-apiserver
    source_address_prefix      = "82.132.219.46"
    destination_address_prefix = "*"
  }

  security_rule {
# This security rule allows inbound SSH traffic from a specific IP address.
    name                       = "ssh-rule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "82.132.219.46"
    destination_address_prefix = "*"
  }
}
