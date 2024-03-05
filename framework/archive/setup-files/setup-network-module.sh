#!/bin/bash

# Filename: setup-network-module.sh
# Purpose: Generates Terraform configs main.tf, variables.tf, and outputs.tf files for network resources deployment based on the specified environment. It is designed to be run within the env-setup directory.

# Creates a configuration file for Terraform or Kubernetes in the specified directory.
# Usage: create_configuration_file <directory> <filename> <heredoc-content>
function create_config_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Write the content to the file
  echo "$file_content" > "$file_path"

  # Check if the file was created successfully
  if [ ! -f "$file_path" ]; then
    echo "Failed to create ${file_name} at ${file_dir}"
    return 1
  else
    echo "${file_name} created successfully at ${file_dir}"
    return 0
  fi
}

# Appends provided content to a file in the specified directory, verifying successful operation.
append_to_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Check if the file exists before attempting to append
  if [ ! -f "$file_path" ]; then
    echo "File ${file_name} does not exist at ${file_dir}"
    return 1
  fi

  # Append the content to the file
  echo "$file_content" >> "$file_path"

  # Verify that the file still exists after appending
  if [ ! -f "$file_path" ]; then
    echo "Failed to append to ${file_name} at ${file_dir}"
    return 1
  else
    echo "Content appended successfully to ${file_name} at ${file_dir}"
    return 0
  fi
}


# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  echo "Usage: $0 <environment>"
  exit 1
fi

ENVIRONMENT=$1
MY_PUBLIC_IP=$(curl -s ifconfig.me)
# Create directories if they don't exist
# Create TF_NETWORK_MODULE_DIR if it doesn't exist
if [ ! -d "$TF_NETWORK_MODULE_DIR" ]; then
  mkdir -p "$TF_NETWORK_MODULE_DIR"
  chown "$(whoami)":"$(whoami)" "$TF_NETWORK_MODULE_DIR"  # Set ownership of the directory
fi

# Create TF_ENV_DIR if it doesn't exist
if [ ! -d "$TF_ENV_DIR" ]; then
  mkdir -p "$TF_ENV_DIR" || { echo "Failed to create $TF_ENV_DIR"; exit 1; }
  chown "$(whoami)":"$(whoami)" "$TF_ENV_DIR"  # Set ownership of the directory
fi

# The second octet for subnet CIDRs.

# Define the heredoc content for main.tf as a string
read -r -d '' main_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

resource "azurerm_resource_group" "vnet_rg" {
  name     = var.network_resource_group_name_input
  location = var.network_resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  resource_group_name = azurerm_resource_group.vnet_rg.name
  location            = azurerm_resource_group.vnet_rg.location
  address_space       = ["10.\${var.vnet_subnet_octet}.0.0/\${var.vnet_subnet_mask}"]
}

resource "azurerm_subnet" "control_plane_subnet" {
  name                 = "control-plane-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.\${var.control_plane_subnet_octet}.0.0/\${var.control_plane_subnet_mask}"]
}

resource "azurerm_subnet" "worker_node_subnet" {
  name                 = "worker-node-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.\${var.worker_node_subnet_octet}.0.0/\${var.worker_node_subnet_mask}"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name

security_rule {
    name                       = "kube-apiserver-rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "\${var.kube_apiserver_rule_port_number}" # default port for kube-apiserver: 6443
    source_address_prefix      = "\${var.public_ip}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh-rule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "\${var.ssh_rule_port_number}}"
    source_address_prefix      = "\${var.public_ip}"
    destination_address_prefix = "*"
  }
}
EOF

# Define the heredoc content for variables.tf as a string
read -r -d '' variables_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

variable "network_resource_group_name_input" {
  description = "The name of the Resource Group where networking resources will be deployed."
  type        = string
  default     = "networking-rg-$ENVIRONMENT"
}

variable "network_resource_group_location" {
  description = "The Azure region where network resources will be deployed."
  type        = string
  default     = "UK South"
}

variable "vnet_address_space_output" {
  description = "The address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod, staging)."
  type        = string
  default     = "$ENVIRONMENT"
}

variable "public_ip" {
  description = "Public IP address to whitelist for SSH and Kubernetes API server access."
  type        = string
  default     = "$MY_PUBLIC_IP"
}

variable "vnet_subnet_octet" {
  description = "# Second octet used in the CIDR block for the entire VNet, defining its IP address range."
  type        = string
  default     = "10"
}

variable "vnet_subnet_mask" {
  description = "Length for the Virtual Network's CIDR block, defines the entire IP address range for the VNet"
  type        = string
  default     = "16" 
}

variable "control_plane_subnet_octet" {
  description = "Second octet used in the CIDR block specifically for the control plane, a subset within the VNet for Kubernetes control components."
  type        = string
  default     = "10"
}

variable "control_plane_subnet_mask" {
  description = "Length for the control plane subnet's CIDR, specifies the size used by the Kubernetes control plane"
  type        = string
  default     = "24" # Assuming a typical /24 subnet mask for control plane subnets
}

variable "worker_node_subnet_octet" {
  description = "Second octet used in the CIDR block specifically for the the worker nodes, a subset within the VNet for Kubernetes worker nodes."
  type        = string
  default     = "10"
}

variable "worker_node_subnet_mask" {
  description = "The CIDR block's subnet mask length that will contain the worker nodes."
  type        = string
  default     = "24" # Assuming a typical /24 subnet mask for control plane subnets
}

variable "kube_apiserver_rule_port_number" {
  description = "The port number used for the Kubernetes API server"
  type        = number
  default     = 6443
}

variable "ssh_rule_port_number" {
  description = "The port number used for SSH access"
  type        = number
  default     = 22
}

variable "vnet_id_output" {
  description = "The ID of the Virtual Network (VNet)."
  type        = string
}

variable "control_plane_subnet_id_output" {
  description = "The ID of the control plane subnet within the VNet."
  type        = string
}

variable "control_plane_subnet_address_output" {
  description = "The address prefixes of the control plane subnet within the VNet."
  type        = list(string)
}

variable "worker_node_subnet_id_output" {
  description = "The ID of the worker node subnet within the VNet."
  type        = string
}

variable "worker_node_subnet_address_output" {
  description = "The address prefixes of the worker node subnet within the VNet."
  type        = list(string)
}

variable "aks_nsg_id_output" {
  description = "The ID of the Network Security Group (NSG) associated with the AKS cluster."
  type        = string
}
EOF

# Define the heredoc content for outputs.tf as a string
read -r -d '' outputs_tf_content <<EOF || true
# This file was created by setup-network-module.sh for the network module.

output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "network_resource_group_name_env" {
  description = "The name of the Resource Group where networking resources are deployed."
  value       = azurerm_resource_group.vnet_rg.name
}

output "control_plane_subnet_id" {
  description = "The ID of the control plane subnet within the VNet"
  value       = azurerm_subnet.control_plane_subnet.id
}

output "control_plane_subnet_address" {
  description = "The address prefixes of the control plane subnet within the VNet"
  value       = azurerm_subnet.control_plane_subnet.address_prefixes
}

output "worker_node_subnet_id" {
  description = "The ID of the worker node subnet within the VNet"
  value       = azurerm_subnet.worker_node_subnet.id
}

output "worker_node_subnet_address" {
  description = "The address prefixes of the worker node subnet within the VNet"
  value       = azurerm_subnet.worker_node_subnet.address_prefixes
}

output "aks_nsg_id" {
  description = "The ID of the Network Security Group (NSG)"
  value       = azurerm_network_security_group.nsg.id
}

output "kube_apiserver_rule_port" {
  description = "Sets the port number, typically 6443 by default, for Kubernetes API server communications."
  value       = var.kube_apiserver_rule_port_number
}

output "ssh_rule_port" {
  description = "The port number used for SSH access, typically 22 by default."
  value       = var.ssh_rule_port_number
}
EOF

# Define the heredoc content for terraform.tfvars as a string
read -r -d '' tfvars_content <<EOF || true
# Default network configuration settings for the '$ENVIRONMENT' environment within the AKS Virtual Network (aks-vnet).
# These settings establish the foundational IP address structure and subnet sizing for various components of the AKS cluster.


# Subnet configuration for the Virtual Network (aks-vnet).
vnet_subnet_octet          = "10"  # Second octet for the entire VNet IP address range
control_plane_subnet_octet = "10"  # Second octet for the Kubernetes control plane components, a subset within the VNet CIDR.
worker_node_subnet_octet   = "10"  # Second octet for the Kubernetes worker nodes subnet CIDR, a subset within the VNet.

# Subnet mask lengths determining the size of each subnet within the Virtual Network.
vnet_subnet_mask           = "16" # Length of the entire IP address range for the VNet
control_plane_subnet_mask  = "24" # Length of the the subnet IP address range used by the Kubernetes control plane.
worker_node_subnet_mask    = "24" # Length of the the subnet IP address range that will contain the worker nodes.

# Kubernetes Configurations
kube_apiserver_rule_port_number = "6443" # The port number used for the Kubernetes API server
ssh_rule_port_number            = "22"   # The standard TCP port (22) for Secure Shell (SSH) access to nodes.
EOF

# Call the function to create the main.tf file with the provided content
create_config_file "$TF_NETWORK_MODULE_DIR" "main.tf" "$main_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_DIR/main.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_DIR" "variables.tf" "$variables_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_DIR/variables.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_DIR" "outputs.tf" "$outputs_tf_content" || { echo "Failed to create $TF_NETWORK_MODULE_DIR/outputs.tf"; exit 1; }
create_config_file "$TF_NETWORK_MODULE_DIR" "terraform.tfvars" "$tfvars_content" || { echo "Failed to create $TF_NETWORK_MODULE_DIR/terraform.tfvars"; exit 1; }

