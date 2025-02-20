# This file was created by create-aks-cluster.sh as Variable definitions for the AKS cluster module.

# variables.tf in the AKS module

# Defines core attributes of the AKS cluster like name and version, essential for cluster creation.
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
  # Default values for AKS cluster setup.
  default = {
    cluster_name            = "aks-cluster-neogenomics"
    location                = "uksouth"
    resource_group_name     = "aks-rg"
    dns_prefix              = "neogenomics"
    kubernetes_version      = "1.18.14"
    tags                    = {}
  }
}

# Specifies AKS network plugin and policy, key for cluster communication and security.
variable "aks_network_profile" {
  description = "Specifies network plugin and policy for AKS, impacting connectivity and security."
  type = object({
    network_plugin     = string
    network_policy     = string
  })
  # Default network profile specifies 'azure' plugin and 'calico' policy.
  default = {
    network_plugin = "azure"
    network_policy = "calico"
  }
}

# The ID of the Virtual Network (VNet).
# This value is used to connect the AKS cluster to the VNet.
variable "vnet_id" {
  description = "The ID of the Virtual Network (VNet)."
  type        = string
}

# The ID of the control plane subnet within the VNet.
# This value is used to specify the subnet where the control plane components of the AKS cluster will be deployed.
variable "control_plane_subnet_id" {
  description = "The ID of the control plane subnet within the VNet."
  type        = string
}

# The ID of the worker node subnet within the VNet.
# This value is used to specify the subnet where the worker nodes of the AKS cluster will be deployed.
variable "worker_node_subnet_id" {
  description = "The ID of the worker node subnet within the VNet."
  type        = string
}

# The ID of the Network Security Group (NSG).
# This value is used to associate the NSG with the AKS cluster for security rule enforcement and traffic filtering.
variable "aks_nsg_id" {
  description = "The ID of the Network Security Group (NSG)."
  type        = string
}
