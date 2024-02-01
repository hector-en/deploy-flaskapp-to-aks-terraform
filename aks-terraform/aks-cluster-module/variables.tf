# This script was created by solution-issue09.sh.

# Input variable for the name of the AKS cluster to be created.
# This value will be used when creating the AKS resource in Azure.
variable "aks_cluster_name" {
  description = "The name of the AKS cluster to be created."
  type        = string
}

# Input variable for the Azure region where the AKS cluster will be deployed.
# This value determines the physical location of your AKS cluster.
variable "cluster_location" {
  description = "The Azure region where the AKS cluster will be deployed."
  type        = string
}

# Input variable for the DNS prefix of the cluster.
# This value is used to create a unique fully qualified domain name (FQDN) for the AKS cluster.
variable "dns_prefix" {
  description = "The DNS prefix of the cluster."
  type        = string
}

# Input variable for the Kubernetes version the cluster will use.
# This value determines which version of Kubernetes your AKS cluster will run.
variable "kubernetes_version" {
  description = "The Kubernetes version the cluster will use."
  type        = string
}

# Input variable for the Client ID for the service principal associated with the cluster.
# This value is used for Azure Active Directory authentication when the AKS cluster interacts with other Azure services.
variable "service_principal_client_id" {
  description = "The Client ID for the service principal associated with the cluster."
  type        = string
}

# Input variable for the Client Secret for the service principal.
# This value is used for Azure Active Directory authentication when the AKS cluster interacts with other Azure services.
variable "service_principal_secret" {
  description = "The Client Secret for the service principal."
  type        = string
}

# Input variables from the networking module
# These values are outputs from the networking module and are used to connect the AKS cluster to the correct network resources.

# The name of the Azure Resource Group where the networking resources were provisioned.
variable "resource_group_name" {
  description = "The name of the Azure Resource Group for networking resources."
  type        = string
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
