Utilities Directory Overview
----------------------------

The 'utilities' directory contains a collection of scripts that provide essential functions for managing Azure resources, Kubernetes deployments, and Terraform operations. These utility scripts are designed to be sourced into other scripts within the project to facilitate common tasks such as creating service principals, configuring kubectl, and applying Terraform plans.

Contents:
---------

1. azure.sh
   - A script containing functions for interacting with Azure resources. It includes functions for creating new service principals and key vaults, assigning roles, checking Azure CLI installation, and exporting tenant and subscription IDs.

2. kubernetes.sh
   - This script provides functions for managing Kubernetes resources via kubectl and Azure CLI. Functions include verifying kubectl context, configuring kubectl with AKS credentials, checking rollout status, starting port forwarding, accessing applications, monitoring pod logs, and describing Kubernetes resources.

3. terraform.sh
   - Contains functions related to Terraform operations. It sources several libraries for error handling, commands, dialog utilities, and file utilities. The script includes functions to ensure the installation of jq and kubectl, set up environment variables for Terraform, run setup scripts, delete AKS resources, and verify AKS cluster connectivity.

Usage:
------

To use these utility scripts, source the desired script at the beginning of your shell script using the `source` command. For example:

source "/path/to/utilities/azure.sh"

Once sourced, you can call any function defined within the script as if it were a part of your own script. This allows for modular and reusable code across different parts of the project.



Note:

These scripts are intended for use by developers and operations teams who have a working knowledge of Azure, Kubernetes, Terraform, and shell scripting. They should be used with an understanding of the actions they perform, especially when modifying cloud resources or sensitive configurations.

Always review the functions and their associated comments before using them to ensure they meet the needs of your specific task or workflow.