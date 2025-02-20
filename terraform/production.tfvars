# Terraform settings for the 'production' environment.

# AKS cluster configuration for the AKS module.
client_id       = "9c97337e-c317-4c6a-ba47-9da601da72ae"
client_secret   = "j3X8Q~frPctPudvt3OaAK5UaY7oX1JFE3pYVtayI"
tenant_id       = "547dc838-060b-4de3-bfc8-34726dabe4a5"
subscription_id = "340c8ae6-c5f6-45cc-8d6e-28f55f03547b"

aks_config = {
  cluster_name        = "aks-cluster-neogenomics-production",
  location            = "uksouth",
  resource_group_name = "aks-rg-production",
  dns_prefix          = "neogenomics-production",
  kubernetes_version  = "1.20.5",
  tags                = {
    Environment = "production",
    Project     = "neogenomics",
    Owner       = "NeoGenomics"
  }
}

# Network profile configuration for the AKS cluster.
aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-production",
    location = "uksouth",
    tags     = {
      Environment = "production",
      Project     = "neogenomics",
      Owner       = "NeoGenomics"
    }
  },
  vnet = {
    name           = "aks-vnet-production",
    address_space  = ["10.30.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-production",
      address_prefixes = ["10.30.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-production",
      address_prefixes = ["10.30.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-production",
    security_rules = [
      {
        name                       = "kube-apiserver-rule",
        priority                   = 1001,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "6443",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      },
      {
        name                       = "ssh-rule",
        priority                   = 1002,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "22",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      }
      // Additional security rules can be added here as needed.
    ]
  }
}
