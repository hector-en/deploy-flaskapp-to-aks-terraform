#!/bin/bash

# Filename: setup-root-configuration.sh
# Purpose: Generates root Terraform configuration files for AKS and network deployment.

# Source automation scripts
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/utilities/file-utilities.sh"; exit 1; }

# Define the heredoc content for main.tf as a string
read -r -d '' main_tf_content <<EOF || true
# Main Terraform configuration for setting up network and AKS resources.

# Provider block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Use the latest compatible version after 3.0.0
    }
  }
}

# Configure the Azure provider with authentication details from the azure_auth map.
provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Import the network module and pass environment-specific variables.
module "network" {
  source = "./modules/network"
  
  network_infrastructure = var.network_infrastructure
}

# Import the AKS cluster module and provide required variables.
module "aks" {
  source = "./modules/aks"

  aks_config = {
    cluster_name            = var.aks_config.cluster_name
    location                = var.aks_config.location
    resource_group_name     = var.aks_config.resource_group_name
    dns_prefix              = var.aks_config.dns_prefix
    kubernetes_version      = var.aks_config.kubernetes_version
    tags                    = var.aks_config.tags
  }

  vnet_id                 = module.network.network_details.vnet.id
  control_plane_subnet_id = module.network.network_details.subnets["control_plane_subnet"]
  worker_node_subnet_id   = module.network.network_details.subnets["worker_node_subnet"]
  aks_nsg_id              = module.network.network_details.nsg_id

  aks_network_profile = var.aks_network_profile
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
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
EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# Output definitions for the root module.

# Outputs from the network module.
output "network_details" {
  description = "Details of the networking resources provisioned by the network module."
  value       = module.network.network_details
}

# Outputs from the AKS cluster module.
output "aks_cluster_details" {
  description = "Details of the AKS cluster provisioned by the AKS module."
  value       = module.aks.aks_cluster_details
  sensitive   = false
}
EOF

# Call the function to create the terraform.tfvars file with the provided content
create_config_file "$TF_ENV_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_ENV_DIR/main.tf"; exit 1; }
create_config_file "$TF_ENV_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_ENV_DIR/variables.tf"; exit 1; }
create_config_file "$TF_ENV_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_ENV_DIR/outputs.tf"; exit 1; }
