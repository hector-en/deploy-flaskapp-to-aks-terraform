# This file was created by create-aks-cluster.sh for the AKS cluster module.

resource "azurerm_resource_group" "rg" {
  name     = var.aks_config.resource_group_name
  location = var.aks_config.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_config.cluster_name
  location            = azurerm_resource_group.rg.location # Corrected typo 'locstion' to 'location'
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_config.dns_prefix
  tags                = var.aks_config.tags

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2_v2"
    vnet_subnet_id  = var.worker_node_subnet_id  # Corrected line
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = var.aks_network_profile.network_plugin
    network_policy = var.aks_network_profile.network_policy
    # Additional network profile attributes can be referenced here if defined.
  }
}
