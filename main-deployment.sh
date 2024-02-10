#!/bin/bash

# main-deployment.sh: End-to-End orchestration script for automating the deployment of an Azure Kubernetes Service (AKS) cluster and a web application using Terraform and Kubernetes.
# This script handles the entire process from provisioning the AKS cluster with Terraform to deploying the Kubernetes manifest.
# It ensures that the infrastructure is provisioned before attempting to deploy the application.

# The script performs the following actions:
# - Initializes Terraform within the specified directory.
# - Creates a Terraform plan and applies it to provision the AKS cluster.
# - Deploys the web application to the AKS cluster using the Kubernetes manifest file.

# Usage:
# Execute this script to start the end-to-end deployment process. No arguments are required.
# ./main-deployment.sh

# Prerequisites:
# Ensure you have Terraform installed and configured correctly, as well as the necessary permissions to execute Terraform commands and interact with the AKS cluster.
# Make sure the AKS cluster and Kubernetes configurations are correctly set up in their respective directories.

# Output:
# The script will output the progress and result of each step in the deployment process.

# Source the required scripts for creating the AKS cluster and deploying the application
source ./aks-terraform/aks-create-cluster.sh
source ./kubernetes/aks-deploy-cluster.sh

# Define variables for Terraform actions
TERRAFORM_PLAN="tfplan" # Changed from "tfplans" to "tfplan" to represent a plan file
TERRAFORM_DIR="./aks-terraform" # Replace with the path to your Terraform directory

# Function to initialize and apply Terraform configuration
initialize_and_apply_terraform() {
  echo "Initializing Terraform..."
  terraform -chdir="$TERRAFORM_DIR" init
  
  echo "Creating Terraform plan..."
  terraform -chdir="$TERRAFORM_DIR" plan -out="$TERRAFORM_PLAN"
  
  echo "Applying Terraform plan..."
  terraform -chdir="$TERRAFORM_DIR" apply "$TERRAFORM_PLAN"
}

# Main function to orchestrate the entire process
main_orchestration() {
  # Provision the AKS cluster using Terraform
  initialize_and_apply_terraform

  # Deploy the application to the AKS cluster using Kubernetes
  deploy_to_aks
}

# Execute the main orchestration function
main_orchestration

echo "End-to-end orchestration has completed."