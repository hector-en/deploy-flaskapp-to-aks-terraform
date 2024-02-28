#!/bin/bash

: <<'END_COMMENT'
This script generates the main.tf, variables.tf, and outputs.tf files for the AKS cluster module based on the specified environment. It is designed to be run within the env-setup directory of the AiCoreDevOpsCapstone project.

The script creates:
- main.tf with the resource definitions for the AKS cluster.
- variables.tf with variable declarations used in main.tf.
- outputs.tf with output values that provide information about the provisioned resources.

Additionally, it generates a terraform.tfvars file with environment-specific variable values that should be customized to define the infrastructure for that environment.

To run this script, follow these steps:
1. Navigate to the env-setup directory inside the terraform main module path.
2. Save this script as setup-aks-cluster.sh.
3. Give execute permissions to the script: chmod +x setup-aks-cluster.sh
4. Run the script with an environment name: ./setup-aks-cluster.sh <environment>
END_COMMENT

# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  echo "Usage: $0 <environment>"
  exit 1
fi

# Source automation scripts
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/utilities/setupfiles.sh"; exit 1; }

# Define the heredoc content for main.tf for the AKS cluster module as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

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
    #dns_service_ip     = "10.0.0.10"
    #docker_bridge_cidr = "172.17.0.1/16"
    # `docker_bridge_cidr` has been deprecated and is no longer supported by the AKS API.
    # It should been commented out together with `dns_service_ip` as it will be removed in version 4.0 of the AzureRM provider.
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

EOF

# Define the heredoc content for variables.tf for the AKS cluster module as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

variable "resource_group_name" {
  description = "Represents the Resource Group where AKS cluster resources will be deployed."
  type        = string
  default     = "aks-cluster-rg"
}

variable "resource_group_location" {
  description = "Represents the Location where AKS cluster resources will be deployed."
  type        = string
  default     = "UK South"
}


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
  default     = "uksouth"
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

/*
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
*/

# Input variables from the networking module
# These values are outputs from the networking module and are used to connect the AKS cluster to the correct network resources.

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

EOF

# Define the heredoc content for outputs.tf for the AKS cluster module as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by setup-aks-cluster.sh for the AKS cluster module.

# Output variable that stores the name of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_cluster_name" {
  description = "The name of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

# Output variable that stores the ID of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_cluster_id" {
  description = "The ID of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

# Output variable that captures the Kubernetes configuration file of the provisioned AKS cluster.
# The value comes from main.tf.
output "aks_kubeconfig" {
  description = "The Kubernetes configuration file of the provisioned AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
EOF

# Call the function to create the files with the provided content
create_config_file "$TF_AKS_MODULE_FILES_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/main.tf"; exit 1; }
create_config_file "$TF_AKS_MODULE_FILES_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/variables.tf"; exit 1; }
create_config_file "$TF_AKS_MODULE_FILES_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_AKS_MODULE_FILES_DIR/outputs.tf"; exit 1; }

