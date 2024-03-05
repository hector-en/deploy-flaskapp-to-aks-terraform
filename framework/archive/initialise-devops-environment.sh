#!/bin/bash

# Source cluster configuration
source cluster-config.sh
# Source Azure DevOps configurations
source devops-config.sh

# Function to install and configure Azure DevOps CLI
install_and_configure_azure_devops_cli() {
    # Install Azure CLI if not already installed
    if ! command -v az &> /dev/null; then
        echo "Installing Azure CLI..."
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi

    # Install Azure DevOps extension if not already installed
    if ! az extension show --name azure-devops &> /dev/null; then
        echo "Installing Azure DevOps CLI extension..."
        az extension add --name azure-devops
    fi

    # Log in to Azure if not already logged in
    if ! az account show &> /dev/null; then
        echo "Logging in to Azure..."
        az login
    fi

    # Configure default Azure DevOps organization
    echo "Configuring Azure DevOps CLI with default organization..."
    az devops configure --defaults organization=$AZURE_DEVOPS_ORG_URL
}

# Function to create a new Azure DevOps project using Azure CLI
create_project() {
    local project_name=$AZURE_DEVOPS_PROJECT_NAME
    local description=$AZURE_DEVOPS_PROJECT_DESCRIPTION
    local visibility=$AZURE_DEVOPS_PROJECT_VISIBILITY

    # Check if the user is logged into Azure DevOps
    if ! az devops -h &> /dev/null; then
        echo "Please log in to Azure DevOps with 'az login' and 'az devops login'."
        exit 1
    fi

    # Check if the project already exists
    if az devops project show --project "$project_name" --output none &> /dev/null; then
        echo "Project '$project_name' already exists."
        return 0
    fi

    # Create a new project if it does not exist
    echo "Creating new Azure DevOps project: $project_name"
    az devops project create \
        --name "$project_name" \
        --description "$description" \
        --visibility "$visibility" \
        --output table

    # Check for successful creation
    if [ $? -ne 0 ]; then
        echo "Failed to create project '$project_name'."
        return 1
    else
        echo "Project '$project_name' created successfully."
    fi
}

# Function to create a service connection to Docker Hub
create_docker_service_connection() {
    # Use Azure DevOps CLI or REST API calls to create a service connection
    # Requires DOCKER_HUB_TOKEN for authentication
}

# Function to create a service connection to AKS
create_aks_service_connection() {
    # Use Azure DevOps CLI or REST API calls to create a service connection
    # Requires credentials for authentication
}

# Main execution
install_and_configure_azure_devops_cli
create_project
create_docker_service_connection "$DOCKER_HUB_CONNECTION_NAME" "$DOCKER_HUB_TOKEN"
create_aks_service_connection "$AKS_SERVICE_CONNECTION_NAME"


# Check for errors and exit if any step fails
