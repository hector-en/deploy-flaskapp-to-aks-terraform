# Main Terraform configuration for setting up network and AKS resources.

# Provider block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Use the latest compatible version after 3.0.0
    }
  }
}

# Configure the Azure provider with authentication details from the azure_auth map.
provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Import the network module and pass environment-specific variables.
module "network" {
  source = "./modules/network"
  
  network_infrastructure = var.network_infrastructure
}

# Import the AKS cluster module and provide required variables.
module "aks" {
  source = "./modules/aks"

  aks_config = {
    cluster_name            = var.aks_config.cluster_name
    location                = var.aks_config.location
    resource_group_name     = var.aks_config.resource_group_name
    dns_prefix              = var.aks_config.dns_prefix
    kubernetes_version      = var.aks_config.kubernetes_version
    tags                    = var.aks_config.tags
  }

  vnet_id                 = module.network.network_details.vnet.id
  control_plane_subnet_id = module.network.network_details.subnets["control_plane_subnet"]
  worker_node_subnet_id   = module.network.network_details.subnets["worker_node_subnet"]
  aks_nsg_id              = module.network.network_details.nsg_id

  aks_network_profile = var.aks_network_profile
}
