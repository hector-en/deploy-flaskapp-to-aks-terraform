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
