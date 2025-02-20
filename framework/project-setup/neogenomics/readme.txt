Project Setup - My Flask Webapp Directory Overview
--------------------------------------------------

The 'project-setup/my-flask-webapp' directory contains scripts and configurations that are essential for setting up the infrastructure and deployment of the "My Flask Webapp" application. These scripts automate the creation of Terraform configuration files, Kubernetes manifests, and other necessary components to streamline the deployment process across different environments such as testing, staging, and production.

Contents:
---------

1. create-deployment_files.sh
   - This script generates deployment scripts (`deploy.sh` and `rollout.sh`) which are used to deploy Kubernetes resources using Kustomize or Helm based on the specified environment.

2. create-aks-modules.sh
   - A utility script that creates Terraform configuration files (`main.tf`, `variables.tf`, and `outputs.tf`) for the AKS cluster module, defining the necessary resources for the Azure Kubernetes Service (AKS) setup.

3. create-k8s-files.sh
   - Responsible for creating base and overlay Kubernetes manifests along with Kustomize configurations for the AKS cluster setup across multiple environments.

4. create-network-modules.sh
   - Generates Terraform configuration files for network resources deployment, including the main network module file (`main.tf`), variable definitions (`variables.tf`), and output values (`outputs.tf`).

5. setup-root-configuration.sh
   - Creates root Terraform configuration files (`main.tf`, `variables.tf`, and `outputs.tf`) for setting up both AKS and network resources in a structured manner.

Usage:
------

To use these scripts, navigate to the 'project-setup/my-flask-webapp' directory and execute the desired script with any necessary arguments as per the instructions within the script. For example, to generate all necessary Kubernetes files, you would run:

./create-k8s-files.sh

Each script is well-documented with comments explaining its purpose and usage. Ensure that you have the correct permissions and prerequisites installed before running these scripts.



Note:
-----
These scripts are designed for developers and operations teams who are familiar with Terraform, Kubernetes, and Azure. They should be used with caution, as they can affect the state of cloud resources and services. Always review the scripts and understand their actions before executing them.