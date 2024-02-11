#!/bin/bash
: '
 It creates a main.tf, variables.tf and outputs.tf files in the main directory.
 Instructions to run this script:

 1. Save this script as solution_issue12.sh in the config directory inside the aks-terraform main module path.
 2. Give execute permissions to the script: chmod +x solution_issue12.sh
 3. Run the script: ./solution_issue12.sh
'
# Create main.tf in aks-terraform root
cat << EOF > ../variables.tf
# This file was created by the solution-issue12.sh script.

# Input variable for the Client ID of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_id" {
  description = "The Client ID of the Azure Service Principal"
  type        = string
}

# Input variable for the Client Secret of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_secret" {
  description = "The Client Secret of the Azure Service Principal"
  type        = string
  sensitive   = true
}

# Input variable for the Tenant ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "tenant_id" {
  description = "The Tenant ID of the Azure account"
  type        = string
}

# Input variable for the Subscription ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "subscription_id" {
  description = "The Subscription ID of the Azure account"
  type        = string
}
EOF
# Print a success message
echo "variables.tf has been successfully created."

# Create main.tf in aks-terraform root
cat << EOF > ../main.tf
# This file was created by the create_aks_cluster.sh script.

# This block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# This block defines the Azure provider and uses the input variables defined above for authentication.
provider "azurerm" {
  features {}

  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
  subscription_id = var.subscription_id
}

# This block imports the networking module and provides values for the required input variables.
module "networking" {
  source = "./networking-module"
  #defaults:
  #resource_group_name = "networking-rg"
  #location            = "UK South"
  #vnet_address_space  = ["10.0.0.0/16"]
}

# This block imports the AKS cluster module and provides values for the required input variables.
module "aks_cluster" {
  source = "./aks-cluster-module"

  aks_cluster_name             = "aicoretemp-aks-cluster"
  cluster_location             = "UK South"
  dns_prefix                   = "aicoretemp"  # updated DNS prefix
  kubernetes_version           = "1.26.6"
  service_principal_client_id  = var.client_id
  service_principal_secret     = var.client_secret
  resource_group_name          = module.networking.resource_group_name
  vnet_id                      = module.networking.vnet_id
  control_plane_subnet_id      = module.networking.control_plane_subnet_id
  worker_node_subnet_id        = module.networking.worker_node_subnet_id
  aks_nsg_id                   = module.networking.aks_nsg_id
}
EOF
# Print a success message
echo "main.tf has been successfully created."

# Create outputs.tf in aks-terraform root
cat << EOF > ../outputs.tf
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
EOF
# Print a success message
echo "outputs.tf has been successfully created."





