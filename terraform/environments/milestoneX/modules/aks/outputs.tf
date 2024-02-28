# This file was created by setup-aks-cluster.sh for the AKS cluster module.

# Output variable that stores the name of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_cluster_name" {
  description = "The name of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

# Output variable that stores the ID of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_cluster_id" {
  description = "The ID of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

# Output variable that captures the Kubernetes configuration file of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_kubeconfig" {
  description = "The Kubernetes configuration file of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
