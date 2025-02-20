# Terraform settings for the 'testing' environment.

# AKS cluster configuration for the AKS module.
client_id       = "9c97337e-c317-4c6a-ba47-9da601da72ae"
client_secret   = "j3X8Q~frPctPudvt3OaAK5UaY7oX1JFE3pYVtayI"
tenant_id       = "547dc838-060b-4de3-bfc8-34726dabe4a5"
subscription_id = "340c8ae6-c5f6-45cc-8d6e-28f55f03547b"

# AKS cluster configuration for testing only.
#client_id       = "4508e9c8-4392-4475-a0b4-8dd3a9284d37"
#client_secret   = "M.o8Q~UqLKUSKxuEZVFR7LXKVuh4~GSARxdJ~adJ"
#tenant_id       = "63b5215c-c406-4ff6-b084-1a221a336dd0"
#subscription_id = "a272056f-85b6-4213-9e8b-8648c05f09e5"

aks_config = {
  cluster_name        = "aks-cluster-neogenomics-testing",
  location            = "uksouth",
  resource_group_name = "aks-rg-testing",
  dns_prefix          = "neogenomics-testing",
  kubernetes_version  = "1.18.14",
  tags                = {
    Environment = "testing",
    Project     = "neogenomics",
    Owner       = "NeoGenomics"
  }
}

aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-testing",
    location = "uksouth",
    tags     = {
      Environment = "testing",
      Project     = "neogenomics",
      Owner       = "NeoGenomics"
    }
  },
  vnet = {
    name           = "aks-vnet-testing",
    address_space  = ["10.10.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-testing",
      address_prefixes = ["10.10.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-testing",
      address_prefixes = ["10.10.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-testing",
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
    ]
  }
}
