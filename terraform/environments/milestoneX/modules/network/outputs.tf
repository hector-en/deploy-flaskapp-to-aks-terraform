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
