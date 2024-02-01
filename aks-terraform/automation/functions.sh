# Prompts the user with a matrix of options and reads their choice.
function prompt_user_options() {
  echo "Please enter a series of digits to configure your environment:"
  echo "----------------------------------------------------------------"
  echo "1 - Create a new Azure Keyvault and Service Principal"
  echo "2 - Re-create module files"
  
  if [ -f "tfplans/$1" ]; then
    echo "3 - Reinitialize the Terraform cluster"
    echo "----------------------------------------------------------------"
    echo "Plan: $1"
    echo "----------------------------------------------------------------"
    read -p "Hit 'Enter' to apply plan, input digits (e.g., '12') for options: " user_choices
  else
    echo "----------------------------------------------------------------"
    read -p "Press 'Enter' for new workflow, enter digits (e.g., '2'): " user_choices
    # Append option 3 by default if no plan file is found
    user_choices+="3"
  fi
}

# Function to generate a timestamp
function generate_timestamp() {
  date +%Y%m%d-%H%M%S
}

# Function to create a new plan filename with a timestamp
function create_new_plan_filename() {
  local timestamp=$(generate_timestamp)
  echo "tfplan-aks-webapp-${timestamp}"
}

# Generates a timestamp, creates a new plan filename, and determines the final plan filename.
function generate_plan_filename() {
  local new_plan_filename=$(create_new_plan_filename)
  echo "${1:-$new_plan_filename}"
}
# Function to check and install jq if not present
function ensure_jq_installed() {
  if ! command -v jq &> /dev/null; then
    echo "jq could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
    echo "jq has been installed successfully."
  else
    echo "jq is already installed."
  fi
}

# Function to check and install kubectl if not present
function ensure_kubectl_installed() {
  if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found, installing..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "kubectl has been installed successfully."
  else
    echo "kubectl is already installed."
  fi
}

# Function to check Azure CLI login status
function check_azure_cli_login() {
  az account show &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Please log in to the Azure CLI"
    exit
  fi
}

# Prompts user for confirmation to apply a Terraform plan, returning 1 if they decline.
function confirm_plan_apply() {
  while true; do
    read -p "Are you sure you want to apply this Terraform plan? [yes/no]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Apply cancelled by user."; return 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

# Checks for the existence of a Terraform plan file and returns 1 if not found.
function check_plan_file_exists() {
  if [ -f "tfplans/$1" ]; then
    return 0
  else
    echo "Error: Plan file not found at tfplans/$1."
    return 1
  fi
}

# Function to create Terraform configuration files
function create_terraform_configuration_files() {
# Create main.tf in aks-terraform root
cat << EOF > variables.tf
# This file was created by the create_aks_cluster.sh script.

# Input variable for the Client ID of the Azure Service Principal.
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
EOF

# Create main.tf in aks-terraform root
cat << EOF > main.tf
# This file was created by the create_aks_cluster.sh script.

# This block specifies the required provider and its version.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# This block defines the Azure provider and uses the input variables defined above for authentication.
provider "azurerm" {
  features {}

  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
  subscription_id = var.subscription_id
}

# This block imports the networking module and provides values for the required input variables.
module "networking" {
  source = "./networking-module"
  #defaults:
  #resource_group_name = "networking-rg"
  #location            = "UK South"
  #vnet_address_space  = ["10.0.0.0/16"]
}

# This block imports the AKS cluster module and provides values for the required input variables.
module "aks_cluster" {
  source = "./aks-cluster-module"

  aks_cluster_name             = "aicoretemp-aks-cluster"
  cluster_location             = "UK South"
  dns_prefix                   = "aicoretemp"  # updated DNS prefix
  kubernetes_version           = "1.26.6"
  service_principal_client_id  = var.client_id
  service_principal_secret     = var.client_secret
  resource_group_name          = module.networking.resource_group_name
  vnet_id                      = module.networking.vnet_id
  control_plane_subnet_id      = module.networking.control_plane_subnet_id
  worker_node_subnet_id        = module.networking.worker_node_subnet_id
  aks_nsg_id                   = module.networking.aks_nsg_id
}
EOF

# Create outputs.tf in aks-terraform root
cat << EOF > outputs.tf
# This file was created by the create_aks_cluster.sh script.

# Output for AKS cluster name from the aks_cluster module
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks_cluster.aks_cluster_name
}

# Outputs from the networking module
output "networking_vnet_id" {
  description = "The ID of the Virtual Network created by the networking module"
  value       = module.networking.vnet_id
}

output "networking_control_plane_subnet_id" {
  description = "The ID of the control plane subnet created by the networking module"
  value       = module.networking.control_plane_subnet_id
}

output "networking_worker_node_subnet_id" {
  description = "The ID of the worker node subnet created by the networking module"
  value       = module.networking.worker_node_subnet_id
}

output "networking_aks_nsg_id" {
  description = "The ID of the Network Security Group created by the networking module"
  value       = module.networking.aks_nsg_id
}

output "resource_group_name" {
  description = "The name of the resource group where networking resources are provisioned"
  value       = module.networking.resource_group_name
}
EOF
}


# Function to run solution scripts
function run_solution_scripts() {
  echo "Running solution scripts to create the required modules..."
  cd solutions 
  ./solution-issue06.sh
  ./solution-issue07.sh
  ./solution-issue08.sh
  ./solution-issue09.sh
  ./solution-issue10.sh
  ./solution-issue11.sh
  cd ..
}


