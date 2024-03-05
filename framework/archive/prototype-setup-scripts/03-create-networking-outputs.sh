#!/bin/bash 

: '
It creates an outputs.tf file in the networking-module directory with the necessary output variables.

The task was to define output variables for the networking-module. These variables will be used to access and utilize information from the networking module when provisioning the AKS cluster module.

The script creates an outputs.tf file with the following output variables:

- vnet_id: Stores the ID of the Virtual Network (VNet). This will be used within the cluster module to connect the cluster to the defined VNet.
- control_plane_subnet_id: Holds the ID of the control plane subnet within the VNet. This will be used to specify the subnet where the control plane components of the AKS cluster will be deployed to.
- worker_node_subnet_id: Stores the ID of the worker node subnet within the VNet. This will be used to specify the subnet where the worker nodes of the AKS cluster will be deployed to.
- networking_resource_group_name: Provides the name of the Azure Resource Group where the networking resources were provisioned. This will be used to ensure the cluster module resources are provisioned within the same resource group.
- aks_nsg_id: Stores the ID of the Network Security Group (NSG). This will be used to associate the NSG with the AKS cluster for security rule enforcement and traffic filtering.

To run this script, follow these steps:

1. Save this script as solution_issue08.sh in the config directory in the aks-terraform main module path.
2. Give execute permissions to the script: chmod +x solution_issue08.sh
3. Run the script: ./solution_issue08.sh
'

# Create outputs.tf in networking-module

NETWORKING_MODULE_DIR="networking-module"

cat << EOF > $NETWORKING_MODULE_DIR/outputs.tf
# This script was created by solution-issue08.sh.

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
EOF
# Print a success message
echo "$NETWORKING_MODULE_DIR/outputs.tf has been successfully created with the necessary input variables."
