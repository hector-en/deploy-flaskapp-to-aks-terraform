resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
# This resource block creates a resource group in Azure.
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
  name                 = "control-plane-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
# This resource block creates a Virtual Network in Azure.
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "worker_node_subnet" {
  name                 = "worker-node-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
# This resource block creates a Virtual Network in Azure.
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
# This resource block creates a Network Security Group in Azure.
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
# This security rule allows inbound SSH traffic.
# This security rule allows traffic to the kube-apiserver.
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
# This security rule allows inbound SSH traffic.
# This security rule allows traffic to the kube-apiserver.
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
