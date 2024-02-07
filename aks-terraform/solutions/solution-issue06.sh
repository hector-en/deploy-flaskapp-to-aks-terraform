#!/bin/bash

: '
It creates the necessary variables.tf and main.tf files in each module directory: aks-cluster-module and networking-module.

The task was to define input variables for the networking-module. However, considering the project structure, it was decided to split the configuration into two separate modules: aks-cluster-module and networking-module. This approach provides several benefits:

1. Isolation: Each module is responsible for a specific part of the infrastructure (AKS cluster and networking). This separation of concerns makes the configuration easier to understand and maintain.

2. Reusability: Modules can be reused across different environments (dev, staging, production), making the configuration DRY (Don’t Repeat Yourself).

3. Flexibility: Modules can be developed and versioned independently. This modularity allows for more flexible configuration and scaling.

The script first creates a variables.tf file in each module directory with the appropriate variables. Then, it creates a main.tf file that uses these variables to create a resource group. More resources can be added to main.tf as needed for the AKS cluster and networking setup.

To run this script, follow these steps:

1. Save this script as solution_issue06.sh in the parent solutions directory of aks-cluster-module and networking-module.
2. Give execute permissions to the script: chmod +x solution_issue06.sh
3. Run the script: ./solution_issue06.sh
'

# Create variables.tf in aks-cluster-module
cat << EOF > ../aks-cluster-module/variables.tf
# This script was created by solution-issue06.sh.

variable "resource_group_name" {
  description = "Represents the Resource Group where AKS cluster resources will be deployed."
  type        = string
  default     = "aks-cluster-rg"
}
EOF

# Create main.tf in aks-cluster-module
cat << EOF > ../aks-cluster-module/main.tf
# This script was created by solution-issue06.sh.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
EOF

# Create variables.tf in networking-module
cat << EOF > ../networking-module/variables.tf
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
cat << EOF > ../networking-module/main.tf
# This script was created by solution-issue06.sh

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
EOF
# Print a success message
echo "aks-cluster-module/variables.tf has been successfully created with the necessary input variables."
