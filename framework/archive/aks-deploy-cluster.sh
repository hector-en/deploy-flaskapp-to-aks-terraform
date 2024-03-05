#!/bin/bash

# aks-deploy-cluster.sh: Script for orchestrating the deployment of a web application to an AKS cluster using Kubernetes.
# This script sources the necessary functions from kubernetes.sh and defines the required variables for deploying the application.
# It configures kubectl to use AKS credentials, applies the Kubernetes manifest file, checks the rollout status, and verifies that pods are running.

# The script performs the following actions:
# - Configures kubectl to communicate with the specified AKS cluster.
# - Applies the Kubernetes manifest file to create the necessary resources within the AKS cluster.
# - Checks the rollout status of the deployment to ensure it completes successfully.
# - Retrieves and lists all pods matching the specified selector to verify they are up and running as expected.

# Usage:
# Execute this script to deploy the application to the AKS cluster. No arguments are required.
# ./aks-deploy-cluster.sh

# Prerequisites:
# Ensure you have Azure CLI installed and configured with the necessary permissions to interact with your AKS cluster.
# Make sure the Kubernetes manifest file exists at the specified path before running this script.

# Output:
# The script will output the progress and result of each step in the deployment process.

# Source the kubernetes.sh script to use its functions
source "$SCRIPTS_DIR/utilities/kubernetes.sh" || { echo "Failed to source kubernetes.sh"; exit 1; }




# Change to the Terraform directory to fetch output variables
# comment out to test in minikube
# pushd "$TERRAFORM_DIR" > /dev/null
# RESOURCE_GROUP_NAME=$(terraform output -raw $TERRAFORM_OUTPUT_RG)
# AKS_CLUSTER_NAME=$(terraform output -raw $TERRAFORM_OUTPUT_CLNAME)
# popd > /dev/null

# Expected AKS kubectl context
#EXPECTED_AKS_CONTEXT=$AKS_CLUSTER_NAME  
# uncomment to test in minikube
EXPECTED_AKS_CONTEXT='minikube'                                

# Verify the correct kubectl context before deploying
if ! verify_kubectl_context "$EXPECTED_AKS_CONTEXT"; then
  echo "Exiting due to incorrect kubectl context."
  exit 1
fi

MANIFEST_FOLDER=$BASE_DIR

# Prompt user for input options (uncomment if using interactive input)
# prompt_kubernetes_deployment_options

# Check if a digit is in the user's choices
case $user_choices in
  1) 
     delete_kubernetes_yaml_files
     run_aks_kubernetes_solution_scripts
     ;;
  # Add more cases for additional options
  *)
     :
     ;;
esac

# deploy the application to the AKS cluster
echo "Starting deployment to AKS cluster..."

# Check the rollout status of the deployment
check_rollout_status "flask-app-deployment"

# Verify the status and details of the Kubernetes services
verify_service_status "flask-app-service"

# Get pods by selector to verify they are running
verify_pods_status "app=flask-app"

# Initiate port forwarding to access the application locally
LOCAL_PORT=5000
REMOTE_PORT=5000
POD_SELECTOR="app=flask-app"
# Output instructions for local access and testing
echo "Deployment to AKS cluster completed successfully."
echo "Port forwarding is now set up. You can access your web application locally at http://127.0.0.1:$LOCAL_PORT"
echo "Please visit http://127.0.0.1:$LOCAL_PORT and test the functionality of the orders table and Add Order feature."

start_port_forwarding "$LOCAL_PORT" "$REMOTE_PORT" "$POD_SELECTOR"

