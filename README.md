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
5. [Branch Structure](#branch-structure)
6. [Contributors](#contributors)
7. [License](#license)
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



In this fork of the project, we've significantly advanced our DevOps capabilities by containerizing the Flask application with Docker, automating the Azure Kubernetes Service (AKS) cluster deployment using Terraform, Azure CLI, and Kubernetes, which embodies the principles of Infrastructure as Code (IaC) and Configuration as Code (CaC). This comprehensive approach ensures consistent application behavior across different environments, streamlines the provisioning and management of necessary networking resources, and leverages Kubernetes for orchestration to maintain high availability and scalability.

### Key achievements include:

- **Docker Containerization**: We've encapsulated the Flask application and its dependencies into a Docker image for compatibility across any Docker-supported platform. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9001-(create%E2%80%90docker%E2%80%90image)).
- **Terraform Automation**: Leveraging Terraform's declarative language, we've defined data center infrastructure to manage various service providers and custom solutions efficiently. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9008(aks%E2%80%90terraform%E2%80%90end%E2%80%90to%E2%80%90end)).
- **Full AKS Deployment Automation with Kubernetes**: Our automation covers the entire lifecycle of the AKS cluster, including infrastructure provisioning, secrets management with Azure Key Vault, error handling, and secure operations, while Kubernetes orchestrates the container deployment and scaling. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout%E2%80%9001-(kubernetes%E2%80%90manifest%E2%80%90file)).
- **Integration and Helper Scripts**: A suite of scripts complements Terraform and Azure CLI to automate deployment processes, address potential errors, and bolster security measures against configuration drift and sensitive data exposure. [More details](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout%E2%80%9001-(kubernetes%E2%80%90manifest%E2%80%90file)#automation-process-via-bash-scripts).

This comprehensive approach not only enhances the deployment process but also reinforces it against common operational challenges, ensuring a robust and reliable DevOps workflow that fully utilizes the capabilities of Kubernetes within the AKS environment.

### Key steps towards End-to-End AKS Cluster provision:

1. **Create Docker Image:** In this step, we created a Dockerfile and built a Docker image for our application. The Dockerfile specifies the base image to use, the necessary dependencies to install, and the commands to run to start the application. Once the Docker image is built, it can be run on any Docker-enabled platform, ensuring consistent behavior across different environments. Relevant wiki: [devops-01(Create Docker image.)](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9001-(create%E2%80%90docker%E2%80%90image))

2. **Terraform Module Structuring:** We structured our Terraform code into modules, starting with defining input variables in `variables.tf` files within each module directory. This modular approach enhances reusability and maintainability of our IaC setup. Relevant wiki: [devops‐02 (terraform‐module‐structuring).](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9002-(terraform%E2%80%90module%E2%80%90structuring))

3. **AKS Networking Setup:** We defined several resources in the `main.tf` file, including a Virtual Network (VNet), two subnets, and a Network Security Group (NSG). These resources are necessary for setting up an Azure Kubernetes Service (AKS) cluster, which we use to orchestrate our Docker containers. Relevant wiki: [devops‐03 (aks‐networking‐setup).](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9003-(aks%E2%80%90networking%E2%80%90setup))

4. **Define Output Variables for Terraform Networking Module:** We created an `outputs.tf` file to define output variables, which enable us to access and utilize information from the networking module when provisioning the AKS cluster module. The output variables include `vnet_id`, `control_plane_subnet_id`, `worker_node_subnet_id`, `networking_resource_group_name`, and `aks_nsg_id`. Relevant wiki: [devops‐04 (terraform‐output‐variables)](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9004-(terraform%E2%80%90output%E2%80%90variables))

5. **Define Input Variables for AKS Cluster Module:** We continued by defining input variables for the AKS cluster module in a `variables.tf` file in the `aks-cluster-module` directory. These variables allow customization of the AKS cluster and facilitate the sharing of networking configuration details. Relevant wiki: [devops‐05 (aks‐cluster‐variables).](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9005-(aks%E2%80%90cluster%E2%80%90variables))


6. **Define Azure Resources for AKS Cluster Configuration:** We defined the necessary Azure resources within the `main.tf` configuration file of the `aks-cluster-module`. These resources include the AKS cluster, node pool, and service principal. [devops‐06 (AKS‐Cluster‐Resources).](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9006-(AKS%E2%80%90Cluster%E2%80%90Resources))

7. **AKS Cluster Outputs Definition:** We defined output variables within the `outputs.tf` configuration file of the `aks-cluster-module`. These output variables capture essential information about the provisioned AKS cluster. Relevant wiki: [devops‐07 (AKS‐Cluster‐Outputs).](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9007-(AKS%E2%80%90Cluster%E2%80%90Outputs))
     
8. **Full Automation of AKS Cluster Creation with Terraform and Bash** 
   We've automated the Azure Kubernetes Service (AKS) cluster creation `aks-create-cluster.sh`, streamlining infrastructure provisioning, secret management, and error handling with Terraform (IaC). This robust process safeguards against configuration drift and data exposure. More details: [devops‐08(aks‐terraform‐end‐to‐end)](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops%E2%80%9008(aks%E2%80%90terraform%E2%80%90end%E2%80%90to%E2%80%90end)).

9. **Seamless Flask App Deployment on AKS with Rolling Updates via Kubernetes** 
Our Flask app now deploys seamlessly wtih the automation script `aks-deploy-cluster.sh` to AKS with Terraform and Kubernetes (CaC), using rolling updates for high availability.
   For more information on the deployment process and the automation scripts used, please refer to the [rollout‐01 (kubernetes-manifest-file)](https://github.com/edunseng/Web-App-DevOps-Project/wiki/rollout%E2%80%9001-(kubernetes%E2%80%90manifest%E2%80%90file)).

## Getting Started

### Prerequisites

For the application to succesfully run, you need to install the following packages:

- flask (version 2.2.2)
- pyodbc (version 4.0.39)
- SQLAlchemy (version 2.0.21)
- werkzeug (version 2.2.3)

### Usage

To run the application, you simply need to run the `app.py` script in this repository. Once the application starts you should be able to access it locally at `http://127.0.0.1:5000`. Here you will be meet with the following two pages:

1. **Order List Page:** Navigate to the "Order List" page to view all existing orders. Use the pagination controls to navigate between pages.

2. **Add New Order Page:** Click on the "Add New Order" tab to access the order form. Complete all required fields and ensure that your entries meet the specified criteria.

## Technology Stack

- **Backend:** Flask is used to build the backend of the application, handling routing, data processing, and interactions with the database.
- **Frontend:** The user interface is designed using HTML, CSS, and JavaScript to ensure a smooth and intuitive user experience.
- **Database:** The application employs an Azure SQL Database as its database system to store order-related data.
- **Infrastructure as Code (IaC):** Terraform is used to define and provide data center infrastructure using a declarative configuration language.
- **Containerization:** Docker is used to package the application and its dependencies into a standardized unit for software development.
**Configuration as Code (CaC):** Kubernetes is utilized to automate the deployment, scale, and manage the containerized application, ensuring consistent environment setup across development, testing, and production.
## Branch Structure

We used a feature branch workflow for our development process. Here's an overview of the branches we used:

- `main`: This is the default branch where all changes are merged into once they're ready for production.
- `devops`: This branch was used for all DevOps tasks related to containerisatoin with Docker and setting up Infrastructure as Code (IaC) with Terraform. The commits in this branch correspond to the following tasks:
  - `devops-01`: Dockerfile creation and build
  - `devops-02`: Terraform module structuring
  - `devops-03`: AKS networking setup
  - `devops-05`: AKS cluster variables definition
  - `devops-06`: AKS cluster resources configuration
  - `devops-07`: AKS cluster outputs definition
  - `devops-08`: Full automation of AKS cluster creation
  - `rollout-01`: Initiate Rolling Update Deployment

- `feature-01`: This branch was used for adding the delivery date feature to the application.

Each task was developed in its respective branch and then merged into the `main` branch upon completion.
## Contributors 

- [Maya Iuga]([https://github.com/yourusername](https://github.com/maya-a-iuga))

## License

This project is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.
