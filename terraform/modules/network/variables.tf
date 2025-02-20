# This file was created by setup-network-module.sh for the network module.

# Networking Infrastructure Variable

# Combined configuration for Azure networking resources supporting the AKS cluster.
variable "network_infrastructure" {
  description = "Combined configuration for Azure networking resources."
  type = object({
    resource_group = object({
      name     = string
      location = string
      tags      = map(string)
    })
    vnet = object({
      name           = string
      address_space  = list(string)
    })
    subnets = map(object({
      name            = string
      address_prefixes = list(string)
    }))
    nsg = object({
      name             = string
      security_rules   = list(map(any))
    })
  })
  # Default values provide a template for network infrastructure, ensuring essential components like VNet and subnets are predefined.
  default = {
    resource_group = {
      name     = "network-rg"
      location = "UK South"
      tags     = {}
    }
    vnet = {
      name           = "aks-vnet"
      address_space  = ["10.10.0.0/16"]
    }
    subnets = {
      control_plane_subnet = {
        name            = "control-plane-subnet"
        address_prefixes = ["10.10.1.0/24"]
      },
      worker_node_subnet = {
        name            = "worker-node-subnet"
        address_prefixes = ["10.10.2.0/24"]
      }
    }
    nsg = {
      name = "aks-nsg"
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
}
