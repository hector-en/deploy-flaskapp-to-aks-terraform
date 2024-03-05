How to Use the Framework within the DevOps Ecosystem
----------------------------------------------------

This 'howto.txt' guide provides a hands-on approach to using the framework within the DevOps ecosystem, focusing on the integration of Terraform, Kubernetes, and Azure DevOps for infrastructure management.

Step-by-Step Guide:
-------------------

1. **Understanding the Framework Structure**:
   - The 'framework' directory is structured into several key areas: 'cluster-management', 'libraries', 'project-setup', and 'utilities'.
   - The 'terraform' folder will contain your Terraform configuration files (.tf) and state.
   - The 'kubernetes' folder will hold your Kubernetes manifest files, including base configurations and overlays for different environments.
   - The 'azure-devops' folder includes Azure Pipelines configurations for CI/CD processes.

2. **Role of Cluster-Management**:
   - The 'cluster-management' folder is pivotal in managing the lifecycle of Kubernetes clusters. It contains scripts like `cluster-config.sh`, which sets up environment-specific variables, and `cluster-output.sh`, which fetches outputs from Terraform to be used by other scripts.
   - Scripts such as `delete-cluster.sh` are responsible for safely tearing down clusters and associated resources when they are no longer needed.

3. **Creating a New Project**:
   - Inside the 'project-setup' directory, create a new subdirectory for your project, e.g., 'my-new-project'.
   - This new project must contain two essential scripts: `create-deployment-files.sh` and `create-k8s-files.sh`. These scripts need to be adapted to generate the correct Terraform configurations and Kubernetes manifests for your specific project requirements.
     - `create-deployment-files.sh`: Generates deployment scripts (`deploy.sh`, `rollout.sh`, etc.) that orchestrate the provisioning of infrastructure using Terraform and the deployment of applications onto Kubernetes.
     - `create-k8s-files.sh`: Produces Kubernetes manifest files, including base configurations and overlays with kustomization.yaml and patches for services and deployments, tailored to each environment (dev, staging, production).
   - These scripts are crucial because they ensure that the infrastructure and deployment configurations are consistent with the project's architecture and operational needs, enabling repeatable and reliable deployments across environments.

4. **Defining Environments**:
   - Within the `cluster-config.sh` script, define the environments your project requires, such as development, testing, staging, and production. Each environment can have its own set of configurations and resource definitions.
   - For each defined environment, create corresponding `.tfvars` files using the `create-deployment-files.sh` script. These files will contain environment-specific variables for Terraform to use during the infrastructure provisioning process.

5. **Setting Up Individual Environments**:
   - Utilize the `create-k8s-files.sh` script to set up the overlays directories for each environment. These directories will contain a set of Kubernetes configuration files, such as `kustomization.yaml`, `namespace.yaml`, and patches for services and deployments, to tailor the Kubernetes resources to the specific needs of each environment.
   - The rationale behind using overlays is to maintain a base configuration that is common across all environments while allowing for variations in each specific environment through patches and customizations.

6. **Initializing the Framework with init.sh**:
   - The `init.sh` script is the entry point for starting the workflow and plays a crucial role in bootstrapping the entire process.
   - When you run `init.sh`, it performs several key actions:
     - Sources utility scripts from the 'utilities' directory, making functions available for use in subsequent operations.
     - Executes the `create-deployment-files.sh` script from your project's setup directory to generate deployment scripts (`deploy.sh`, `rollout.sh`, etc.) that orchestrate the provisioning of infrastructure using Terraform.
     - Calls upon the `create-k8s-files.sh` script to produce Kubernetes manifest files, including base configurations and overlays tailored to each environment.
     - Ensures that all generated scripts are executable and ready to be used for deploying your infrastructure and applications.
   - It is essential to run the `init.sh` script whenever the `create-deployment-files.sh` or `create-k8s-files.sh` scripts are edited. This ensures that any changes made are propagated through to the generated deployment and Kubernetes configuration files.
   - Additionally, running `init.sh` is a good practice to ensure that the infrastructure is aligned after edits. It helps maintain consistency across your environments and prevents drift between your configuration files and the actual state of your infrastructure.

7. **Deploying by Environment**:
   - After setting up the Terraform workspaces and applying the necessary infrastructure changes, use the `deployment.sh` script to deploy your application onto the Kubernetes cluster. This script will reference the Kubernetes manifests and overlays specific to the chosen environment.
   - The deployment process is designed to be environment-aware, meaning it will apply the correct configurations based on the active Terraform workspace or the specified environment.

8. **Verifying the Deployment**:
   - Verify the infrastructure setup by checking the output of Terraform commands and reviewing the state files.
   - Confirm the successful deployment of your Kubernetes resources by inspecting the rollout status, pod logs, and service endpoints.
   - Ensure that the Azure DevOps pipelines are correctly configured and triggered, resulting in a continuous integration and delivery flow.

Rationale Behind the Workflow:
------------------------------

- The use of `.tfvars` files for each environment allows for customizable and scalable infrastructure provisioning. It enables you to define environment-specific resources, such as different VM sizes, database configurations, or network settings, without altering the core Terraform configuration.
- Kubernetes overlays provide a similar benefit for application deployment, where you can customize aspects like replica counts, resource limits, or environment variables per environment.
- Terraform workspaces offer a clean separation of state files, reducing the risk of cross-environment conflicts and making it easier to manage resources across multiple environments.
- The combination of these tools and practices results in a flexible yet controlled deployment pipeline that can be adapted to various project requirements and scales efficiently with the complexity of the infrastructure.

Best Practices:
---------------

- Test scripts in a development or staging environment before applying them to production.
- Manage secrets securely and avoid hardcoding sensitive information in scripts.
- Regularly update the framework scripts to align with the latest features and best practices of Terraform, Kubernetes, and Azure DevOps.
- Document any customizations or unique configurations within your project setup for clarity and maintainability.

By integrating Terraform for infrastructure provisioning, Kubernetes for container orchestration, and Azure DevOps for CI/CD, this framework facilitates a robust and scalable DevOps ecosystem. The 'cluster-management' folder plays a critical role in ensuring that Kubernetes clusters are consistently managed and integrated with the rest of the infrastructure setup. The `init.sh` script is the entry point that triggers the configuration and deployment processes, ensuring a smooth and automated workflow from start to finish. Running `init.sh` after any modifications to key scripts or to realign infrastructure ensures that your deployments remain consistent and reliable.