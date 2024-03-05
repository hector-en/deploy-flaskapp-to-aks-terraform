# Web-App-DevOps-Project

Welcome to the Web App DevOps Project repo! This project revolves around a Flask web application that streamlines order management and tracking for businesses. It boasts an intuitive user interface for monitoring existing orders and inserting new ones.

In this updated fork, we've integrated Infrastructure as Code (IaC) using Terraform for network provisioning and Docker for application containerization, ensuring consistent deployments. Additionally, we've automated the Azure Kubernetes Service (AKS) cluster creation with Terraform and Bash scripts, enhancing our setup's infrastructure and security. Kubernetes plays a pivotal role in this process, serving as the Configuration as Code (CaC) component that orchestrates container deployment and management, further solidifying our DevOps pipeline.

Each development step is thoroughly documented in our project wiki, with pages linked to their respective commits for easy reference.

Adhering to a feature branch workflow, tasks are developed on individual branches named after the task and then merged into the main branch once finalized.

## Table of Contents

1. [Original Web Application](#original-web-application)
2. [Fork-Specific Updates](#fork-specific-updates)
   - [A) Application Changes](#a-application-changes)
   - [B) DevOps Enhancements](#b-devops-enhancements)
3. [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
   - [Usage](#usage)
4. [Technology Stack](#technology-stack)
5. [Framework Structure](#framework-structure)
6. [Git Structure](#git-structure)
7. [Contributors](#contributors)
8. [License](#license)
## Original Web Application

The original web application provides the following features:

- **Order List:** View a comprehensive list of orders including details like date UUID, user ID, card number, store code, product code, product quantity, order date, and shipping date.
  
![Screenshot 2023-08-31 at 15 48 48](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/3a3bae88-9224-4755-bf62-567beb7bf692)

- **Pagination:** Easily navigate through multiple pages of orders using the built-in pagination feature.
  
![Screenshot 2023-08-31 at 15 49 08](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/d92a045d-b568-4695-b2b9-986874b4ed5a)

- **Add New Order:** Fill out a user-friendly form to add new orders to the system with necessary information.
  
![Screenshot 2023-08-31 at 15 49 26](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/83236d79-6212-4fc3-afa3-3cee88354b1a)

- **Data Validation:** Ensure data accuracy and completeness with required fields, date restrictions, and card number validation.
## Fork-Specific Updates

### A) Application Changes

We've made some changes to the application itself:

**Add Delivery Date Feature:** We added a new feature to the application that allows users to specify a delivery date for their orders. This involved changes to the database schema, the application logic, and the user interface. [See the wiki page for more details.](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9001-(create%E2%80%90docker%E2%80%90image))

### B) DevOps Enhancements

Our latest enhancements include:

- **Automated Namespace Management**: We've implemented `create-k8s-files.sh` to automate the generation of namespace YAML files for each environment, ensuring isolated workspaces for development, staging, and production.
- **Script Refinements**: The `create_deployment_files.sh` script has been updated to streamline the deployment process, incorporating namespace setup and RBAC configurations into the workflow.
- **Context and Namespace Alignment**: Context setting is now managed more efficiently, typically handled by CI/CD pipelines or developers' local setup, aligning `kubectl` with the correct namespaces.
- **Manifest Customization**: With `create-k8s-files.sh`, Kubernetes manifests are dynamically updated to specify namespaces, ensuring resources are deployed correctly.
- **RBAC Configuration**: Access within each namespace is controlled through RBAC configurations defined in Kubernetes manifest files, enhancing security.
- **Resource Quotas**: To prevent any one environment from monopolizing cluster capacity, we've included the generation of ResourceQuota objects within the namespace YAML files.
- **Ingress for Internal Distribution**: As an alternative to port forwarding, we've proposed using Kubernetes Ingress controllers for scalable internal application distribution.

### Key Milestones

- **Docker Containerization**: Encapsulating the Flask application into a Docker image for compatibility across platforms. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐01-(create‐docker‐image)).
- **Terraform Automation**: Defining data center infrastructure with Terraform to manage service providers and custom solutions efficiently. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐08(aks‐terraform‐end‐to‐end)).
- **AKS Deployment Automation**: Automating the entire lifecycle of the AKS cluster, including provisioning, secrets management, error handling, and secure operations. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout‐01-(kubernetes‐manifest‐file)).
- **Enhanced Namespace Management and Ingress Integration**: Refining Kubernetes namespace management and integrating Ingress controllers for secure internal application distribution. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout‐02-(enhanced‐deployment‐framework)).


### Progression to Fully Automated AKS Cluster Deployment

1. **Create Docker Image**: Developed a Dockerfile and built a Docker image for our Flask application, ensuring consistent behavior across different environments. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐01-(create‐docker‐image)).

2. **Terraform Module Structuring**: Organized our Terraform code into modules for better reusability and maintainability of our IaC setup. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐02-(terraform‐module‐structuring)).

3. **AKS Networking Setup**: Configured essential networking resources such as VNet and subnets required for the AKS cluster using Terraform. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐03-(aks‐networking‐setup)).

4. **Output Variables for Terraform Networking Module**: Defined output variables in Terraform to facilitate the sharing of networking configuration details when provisioning the AKS cluster module. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐04-(terraform‐output‐variables)).

5. **Input Variables for AKS Cluster Module**: Specified input variables for customizing the AKS cluster within the Terraform `aks-cluster-module`. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐05-(aks‐cluster‐variables)).

6. **Azure Resources for AKS Cluster Configuration**: Defined Azure resources necessary for the AKS cluster configuration in the `main.tf` file of the `aks-cluster-module`. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐06-(AKS‐Cluster‐Resources)).

7. **AKS Cluster Outputs Definition**: Captured essential information about the provisioned AKS cluster through output variables in the `outputs.tf` file of the `aks-cluster-module`. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐07-(AKS‐Cluster‐Outputs)).

8. **Full Automation of AKS Cluster Creation**: Streamlined the AKS cluster creation process with `aks-create-cluster.sh`, automating infrastructure provisioning, secret management, and error handling. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐08(aks‐terraform‐end‐to‐end)).

9. **Seamless Flask App Deployment on AKS**: Utilized `aks-deploy-cluster.sh` to deploy our Flask app to AKS with rolling updates, ensuring high availability and zero downtime during updates. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout‐01-(kubernetes‐manifest‐file)).

10. **Enhanced Namespace Management and Ingress Integration**: Refined Kubernetes namespace management and introduced Ingress controllers for secure internal application distribution. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout-02-(enhanced‐deployment‐framework)).
## Getting Started

### Prerequisites

For the application to succesfully run, you need to install the following packages:

- flask (version 2.2.2)
- pyodbc (version 4.0.39)
- SQLAlchemy (version 2.0.21)
- werkzeug (version 2.2.3)

### Usage

To run the application locally, execute the `app.py` script within this repository. The application will be accessible at `http://127.0.0.1:5000`, where you can navigate through the Order List Page or add new orders via the Add New Order Page.

For deployment to an AKS cluster:

1. Confirm that the `PROJECT_ENVIRONMENTS` variable in `cluster-config.sh` is set with the desired environments (e.g., `dev`, `staging`, `prod`).
2. Initialize the environment configurations by running `bash init.sh`.
3. Apply Kubernetes configurations across environments with `bash rollout.sh <environment>`, ensuring `<environment>` matches one from `cluster-config.sh`.
4. Deploy the application to the AKS cluster using `bash deploy.sh <environment>`.
-  (Optional) Access the deployed application via port forwarding with `kubectl port-forward svc/my-app-service 5000:80 -n <namespace>`, substituting `<namespace>` with The appropriate namespace for your environment. The `deploy.sh` script includes this step.
5. The application will remain accessible at `http://127.0.0.1:5000`.

These steps provide a streamlined process for both local execution and full AKS deployment, catering to various stages of development and testing.

## Technology Stack

- **Backend:** Flask is used to build the backend of the application, handling routing, data processing, and interactions with the database.
- **Frontend:** The user interface is designed using HTML, CSS, and JavaScript to ensure a smooth and intuitive user experience.
- **Database:** The application employs an Azure SQL Database as its database system to store order-related data.
- **Infrastructure as Code (IaC):** Terraform is used to define and provide data center infrastructure using a declarative configuration language.
- **Containerization:** Docker is used to package the application and its dependencies into a standardized unit for software development.
**Configuration as Code (CaC):** Kubernetes is utilized to automate the deployment, scale, and manage the containerized application, ensuring consistent environment setup across development, testing, and production.

## Framework Structure

The project's framework is meticulously organized into key directories, each tailored to facilitate specific aspects of the DevOps workflow. Each directory includes a `readme.txt` file that provides detailed explanations of its contents and usage:

- **cluster-management**: Manages the lifecycle of Kubernetes clusters.
  - `cluster-config.sh`: Configures environment-specific variables.
  - `cluster-output.sh`: Retrieves outputs from Terraform state.
  - `delete-cluster.sh`: Safely deletes Kubernetes clusters.
  - `devops-config.sh`: Sets up Azure DevOps configurations.
  - `readme.txt`: Describes the purpose and functionality of scripts within this directory.

- **libraries**: Houses shared utility scripts for various operations.
  - `azure_commands.sh`: Azure resource management functions.
  - `dialog-utilities.sh`: Interactive user input prompts.
  - `error-handler.sh`: Error handling for Terraform processes.
  - `file-utilities.sh`: File manipulation utilities.
  - `terraform_commands.sh`: Terraform-specific command functions.
  - `readme.txt`: Provides insights into the library scripts and their applications.

- **project-setup/my-flask-webapp**: Contains setup scripts for the Flask web application.
  - `create-aks-module.sh`: Generates AKS Terraform configurations.
  - `create-k8s-files.sh`: Creates Kubernetes manifests.
  - `create-network-module.sh`: Produces network-related Terraform configs.
  - `create_deployment_files.sh`: Generates Kubernetes deployment scripts.
  - `setup-root-configuration.sh`: Establishes root Terraform configurations.
  - `readme.txt`: Offers guidance on setting up and deploying the Flask application.

- **utilities**: Provides additional support for deployment and management tasks.
  - `azure.sh`: Handles Azure resource management with error handling.
  - `kubernetes.sh`: Manages Kubernetes resources via kubectl.
  - `terraform.sh`: Assists with Terraform infrastructure provisioning.
  - `readme.txt`: Details the utilities available and how to utilize them in the project.

This structured approach underscores our dedication to modular and scalable infrastructure management, adhering to the latest DevOps best practices for efficient and maintainable workflows.
## Git Structure

Our development process adheres to a feature branch workflow, ensuring organized and manageable code changes. Here's an overview of the branches we used:

- `main`: The primary branch where all finalized changes are merged for production release.
- `devops`: Dedicated to comprehensive DevOps tasks, this branch includes containerization with Docker and Infrastructure as Code (IaC) setup using Terraform. It encompasses a series of task-specific branches:
  - `devops-01`: Creation and building of the Dockerfile.
  - `devops-02`: Structuring of Terraform modules for better modularity.
  - `devops-03`: Setup of AKS networking resources.
  - `devops-05`: Definition of AKS cluster variables.
  - `devops-06`: Configuration of AKS cluster resources.
  - `devops-07`: Definition of AKS cluster output variables.
  - `devops-08`: Automation of the entire AKS cluster creation process.
- `rollout`: This branch serves as the hub for our deployment enhancements, focusing on streamlining the delivery pipeline and optimizing Kubernetes configurations. It branches out into specific updates that incrementally improve our deployment strategy:

  - `rollout-01`: Orchestrates rolling updates to achieve zero-downtime deployments, ensuring high availability of services during updates.
  - `rollout-02`: Introduces sophisticated namespace management techniques and leverages Ingress controllers to facilitate secure and scalable internal service exposure
  
- `feature-01`: Utilized for developing the new delivery date feature within the application.

Each feature or task is meticulously developed within its respective branch before being reviewed and merged into the `main` branch.

## Contributors 

- [Maya Iuga]([https://github.com/yourusername](https://github.com/maya-a-iuga))

## License

This project is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.
