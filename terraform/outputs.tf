# Output definitions for the root module.

# Outputs from the network module.
output "network_details" {
  description = "Details of the networking resources provisioned by the network module."
  value       = module.network.network_details
}

# Outputs from the AKS cluster module.
output "aks_cluster_details" {
  description = "Details of the AKS cluster provisioned by the AKS module."
  value       = module.aks.aks_cluster_details
  sensitive   = false
}
