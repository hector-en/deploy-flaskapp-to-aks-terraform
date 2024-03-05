Cluster Management Directory Overview
-------------------------------------

The 'cluster-management' directory is a crucial component of our infrastructure management and orchestration within this project. It contains scripts and configuration files that are used to set up, configure, manage, and tear down Kubernetes clusters specifically tailored for our environments in Azure.

Contents:
---------

1. cluster-config.sh
   - This script holds the environment-specific configuration variables necessary for setting up the Kubernetes cluster. It defines project environments, service principal names, resource groups, and other essential variables required during the cluster setup and deployment process.

2. cluster-output.sh
   - A utility script designed to fetch and export output variables from Terraform state files. These outputs include resource group names, VNet details, subnet IDs, and more, which are vital for interacting with the provisioned Azure resources.

3. delete-cluster.sh
   - This script is responsible for safely deleting the entire Kubernetes cluster, associated Key Vault, and the resource group from Azure. It ensures that all resources are cleaned up when a cluster is no longer needed.

4. devops-config.sh
   - Contains configuration variables for Azure DevOps integration. It includes the organization URL, project name, description, and visibility settings, which are used to set up CI/CD pipelines and other DevOps processes.

Usage:
------

Each script is equipped with detailed comments explaining its purpose and usage. To use these scripts, navigate to the 'cluster-management' directory and execute the desired script with any necessary arguments as per the instructions within the script.

To delete a cluster, simply execute:
./delete-cluster.sh

Please ensure you have the necessary permissions and that you are logged into the Azure CLI before running these scripts.

Note:
-----

These scripts are intended for use by developers and operations teams who are familiar with Azure, Kubernetes, and Terraform. They should be used with caution, as some scripts can affect the state of cloud resources and services.

Always review the scripts and understand their actions before executing them, especially those that perform deletions or modifications to the infrastructure.