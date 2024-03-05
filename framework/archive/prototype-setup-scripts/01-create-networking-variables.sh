#!/bin/bash
: <<'COMMENT'
To run this script, follow these steps:

1. Save this script as 01-setup-networking-module.sh in the env-setup directory inside the
   terraform main module path.
2. Give execute permissions to the script: chmod +x 01-setup-networking-module.sh
3. Run the script with an environment name: ./01-setup-networking-module.sh <environment>
`.
COMMENT

NETWORKING_MODULE_DIR="networking-module"
AKS_MODULE_DIR="aks-cluster-module"

# Create directories if they don't exist
mkdir -p "$NETWORKING_MODULE_DIR"
mkdir -p "$AKS_MODULE_DIR"

# Create variables.tf in aks-cluster-module
cat << EOF > $AKS_MODULE_DIR/variables.tf
# This script was created by solution-issue06.sh.

variable "resource_group_name" {
  description = "Represents the Resource Group where AKS cluster resources will be deployed."
  type        = string
  default     = "aks-cluster-rg"
}
EOF

# Create main.tf in aks-cluster-module
cat << EOF > $AKS_MODULE_DIR/main.tf
# This script was created by solution-issue06.sh.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
EOF

# Create variables.tf in networking-module
cat << EOF > $NETWORKING_MODULE_DIR/variables.tf
# This script was created by solution-issue06.sh

variable "resource_group_name" {
  description = "Represents the Resource Group where networking resources will be deployed."
  type        = string
  default     = "networking-rg"
}

variable "location" {
  description = "Specifies the Azure region where networking resources will be deployed."
  type        = string
  default     = "UK South"
}

variable "vnet_address_space" {
  description = "Defines the address space for the Virtual Network in the main configuration."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}
EOF

# Create main.tf in networking-module
cat << EOF > $NETWORKING_MODULE_DIR/main.tf
# This script was created by solution-issue06.sh

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
EOF
# Print a success message
echo "$AKS_MODULE_DIR/variables.tf has been successfully created with the necessary input variables."


