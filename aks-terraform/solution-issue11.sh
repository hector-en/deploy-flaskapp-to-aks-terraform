#!/bin/bash 

# This script creates an outputs.tf file in the cluster module directory with the necessary output variables.

# Navigate to the cluster module directory
cd aks-cluster-module

# Create the outputs.tf file
cat << EOF > outputs.tf
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
EOF

# Print a success message
echo "aks-cluster-module/outputs.tf has been successfully created with the necessary output variables."

