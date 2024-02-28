#!/bin/bash 
: '
It creates an outputs.tf file in the cluster module directory with the necessary output variables.
Instructions to run this script:
 
 1. Save this script as solution_issue10.sh in the config directory inside the aks-terraform main module path.
 2. Give execute permissions to the script: chmod +x solution_issue11.sh
 3. Run the script: ./solution_issue11.sh
 '
AKS_MODULE_DIR="aks-cluster-module"

# Create the outputs.tf file
cat << EOF > $AKS_MODULE_DIR/outputs.tf
# This script was created by the solution-issue11.sh script. 

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
echo "$AKS_MODULE_DIR/outputs.tf has been successfully created with the necessary output variables."

