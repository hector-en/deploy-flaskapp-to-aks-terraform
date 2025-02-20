# This file was created by create-aks-cluster.sh for the AKS cluster module.

output "aks_cluster_details" {
  description = "Details of the provisioned AKS cluster."
  value = {
    name                = azurerm_kubernetes_cluster.aks.name
    id                  = azurerm_kubernetes_cluster.aks.id
    resource_group_name = azurerm_resource_group.rg.name
  }
  sensitive = false
}
