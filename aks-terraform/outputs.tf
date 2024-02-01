# This file was created by the create_aks_cluster.sh script.

# Output for AKS cluster name from the aks_cluster module
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks_cluster.aks_cluster_name
}

# Outputs from the networking module
output "networking_vnet_id" {
  description = "The ID of the Virtual Network created by the networking module"
  value       = module.networking.vnet_id
}

output "networking_control_plane_subnet_id" {
  description = "The ID of the control plane subnet created by the networking module"
  value       = module.networking.control_plane_subnet_id
}

output "networking_worker_node_subnet_id" {
  description = "The ID of the worker node subnet created by the networking module"
  value       = module.networking.worker_node_subnet_id
}

output "networking_aks_nsg_id" {
  description = "The ID of the Network Security Group created by the networking module"
  value       = module.networking.aks_nsg_id
}

output "resource_group_name" {
  description = "The name of the resource group where networking resources are provisioned"
  value       = module.networking.resource_group_name
}
