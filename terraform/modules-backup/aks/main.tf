# This script was created by the solution-issue10.sh script. 

# This resource block creates the AKS cluster.
resource "azurerm_kubernetes_cluster" "aks" {
  # The name, location, and resource group of the AKS cluster come from input variables defined in variables.tf.
  name                = var.aks_cluster_name
  location            = var.cluster_location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = var.worker_node_subnet_id  # Corrected line
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
    # Removed the incorrect subnet_id line from her
  }

/*  
   # The client_id and client_secret values come from input variables defined in variables.tf.
   # Starting from version 2.0 of the AzureRM provider for Terraform, the identity block is used to define the identity type of the AKS cluster
  service_principal {
    client_id     = var.service_principal_client_id
    client_secret = var.service_principal_secret
  }
*/
  tags = {
    Environment = "Production"
  }
}
