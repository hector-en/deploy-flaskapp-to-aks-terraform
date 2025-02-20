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
