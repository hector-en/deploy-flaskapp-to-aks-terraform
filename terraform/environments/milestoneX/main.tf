# This file was created by 05-setup-root-configuration.sh for the root module.

# This block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # This will get the latest compatible version after 3.0.0
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

# This block imports the network module and provides values for the required input variables.
module "network" {
  source = "./modules/network"
}

# This block imports the AKS cluster module and provides values for the required input variables.
module "aks" {
  source = "./modules/aks"

  aks_cluster_name             = "aicoretemp-aks-cluster"
  dns_prefix                   = "aicoretemp"  # updated DNS prefix
  kubernetes_version           = "1.28.5" # latest non-preview (generally available) version for uksouth after 1.26.6
  #service_principal_client_id  = var.client_id
  #service_principal_secret     = var.client_secret
  #resource_group_name          = var.resource_group_name
  vnet_id                      = module.network.vnet_id
  control_plane_subnet_id      = module.network.control_plane_subnet_id
  worker_node_subnet_id        = module.network.worker_node_subnet_id
  aks_nsg_id                   = module.network.aks_nsg_id
}
