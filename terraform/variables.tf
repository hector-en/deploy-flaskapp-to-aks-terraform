# Variable definitions for the root module.

# Azure Service Principal and Subscription details.
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

variable "network_infrastructure" {
  description = "Combined configuration for Azure networking resources."
  type = object({
    resource_group = object({
      name     = string
      location = string
      tags     = map(string)
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
}

# AKS module configuration variables.
 variable "aks_config" {
  description = "Core configuration for the AKS cluster."
  type = object({
    cluster_name            = string
    location                = string
    resource_group_name     = string
    dns_prefix              = string
    kubernetes_version      = string
    tags                    = map(string)
  })
}

variable "aks_network_profile" {
  description = "Network profile settings for the AKS cluster."
  type = object({
    network_plugin     = string
    network_policy     = string
  })
}
