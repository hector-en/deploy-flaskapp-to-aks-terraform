# Web-App-DevOps-Project

Welcome to the Web App DevOps Project repo! This project is based on a Flask web application that allows you to efficiently manage and track orders for a potential business. It provides an intuitive user interface for viewing existing orders and adding new ones.

In this fork of the project, we've added Infrastructure as Code (IaC) practices using Terraform to define the necessary networking resources for our application. We've also containerized the application using Docker. Each step of the development process is documented in detail in our project wiki. Each wiki page corresponds to the changes made in a specific commit.

We followed a feature branch workflow for our additions and changes. Each task was developed in a separate branch named after the task, then merged into the main branch upon completion.


## Table of Contents

- [Original Web Application](#original-web-application)
- [Application Changes](#application-changes)
- [Containerization](#containerization)
- [Infrastructure as Code (IaC)](#infrastructure-as-code-iac)
- [Getting Started](#getting-started)
- [Technology Stack](#technology-stack)
- [Branch Structure](#branch-structure)
- [Contributors](#contributors)
- [License](#license)
## Original Web Application

The original web application provides the following features:

- **Order List:** View a comprehensive list of orders including details like date UUID, user ID, card number, store code, product code, product quantity, order date, and shipping date.
  
![Screenshot 2023-08-31 at 15 48 48](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/3a3bae88-9224-4755-bf62-567beb7bf692)

- **Pagination:** Easily navigate through multiple pages of orders using the built-in pagination feature.
  
![Screenshot 2023-08-31 at 15 49 08](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/d92a045d-b568-4695-b2b9-986874b4ed5a)

- **Add New Order:** Fill out a user-friendly form to add new orders to the system with necessary information.
  
![Screenshot 2023-08-31 at 15 49 26](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/83236d79-6212-4fc3-afa3-3cee88354b1a)

- **Data Validation:** Ensure data accuracy and completeness with required fields, date restrictions, and card number validation.
## Application Changes

We've made some changes to the application itself:

**Add Delivery Date Feature:** We added a new feature to the application that allows users to specify a delivery date for their orders. This involved changes to the database schema, the application logic, and the user interface. [See the wiki page for more details.](link_to_wiki_page_5)
   - Relevant commit: [feature-01: Add delivery date feature](link_to_commit_5)

Please visit the wiki pages for a detailed walkthrough of each step.
## Containerization

In this fork of the project, we've used Docker to containerize the application. This involves packaging the application and all its dependencies into a Docker image, which can be run consistently on any platform that supports Docker.

1. **Create Docker Image:** In this step, we created a Dockerfile and built a Docker image for our application. The Dockerfile specifies the base image to use, the necessary dependencies to install, and the commands to run to start the application. Once the Docker image is built, it can be run on any Docker-enabled platform, ensuring consistent behavior across different environments. [See the wiki page for more details.](https://github.com/edunseng/Web-App-DevOps-Project/wiki/devops‐01-(create‐docker‐image))
   - Relevant commit: [devops-01: Create Docker image](link_to_commit_1)

## Infrastructure as Code (IaC)

We've used Terraform to define the necessary networking resources for our application. Terraform is an IaC tool that allows us to define and provide data center infrastructure using a declarative configuration language. With Terraform, we can manage a wide variety of service providers as well as custom in-house solutions.

## Full Automation of AKS Cluster Deployment

With the latest updates, we have fully automated the deployment of the Azure Kubernetes Service (AKS) cluster. This includes provisioning infrastructure, managing secrets, handling errors gracefully, and ensuring all operations are conducted securely and idempotently.

The automation is achieved through a combination of Terraform configurations and helper scripts, integrated with Azure CLI for resource management and Azure Key Vault for secrets storage. This ensures a streamlined deployment process that is protected against common pitfalls such as configuration drift and exposure of sensitive data.

For more details on the full automation process, please refer to the [DevOps-08 wiki entry](link_to_wiki_page_9).


The steps we took are as follows:

2. **Terraform Module Structuring:** We structured our Terraform code into modules, starting with defining input variables in `variables.tf` files within each module directory. This modular approach enhances reusability and maintainability of our IaC setup. [See the wiki page for more details on Terraform module structuring.](link_to_wiki_page_2)
   - Relevant commit: [devops-02: Terraform module structuring](link_to_commit_2)

3. **AKS Networking Setup:** We defined several resources in the `main.tf` file, including a Virtual Network (VNet), two subnets, and a Network Security Group (NSG). These resources are necessary for setting up an Azure Kubernetes Service (AKS) cluster, which we use to orchestrate our Docker containers. [See the wiki page for more details.](link_to_wiki_page_3)
   - Relevant commit: [devops-03: Define essential networking resources for AKS cluster](link_to_commit_3)

4. **Define Output Variables for Terraform Networking Module:** We created an `outputs.tf` file to define output variables, which enable us to access and utilize information from the networking module when provisioning the AKS cluster module. The output variables include `vnet_id`, `control_plane_subnet_id`, `worker_node_subnet_id`, `networking_resource_group_name`, and `aks_nsg_id`. [See the wiki page for more details.](link_to_wiki_page_4)
   - Relevant commit: [devops-04: Define output variables for Terraform networking module](link_to_commit_4)

5. **Define Input Variables for AKS Cluster Module:** We continued by defining input variables for the AKS cluster module in a `variables.tf` file in the `aks-cluster-module` directory. These variables allow customization of the AKS cluster and facilitate the sharing of networking configuration details. [See the wiki page for more details.](link_to_wiki_page_6)
   - Relevant commit: [devops-05: Define input variables for AKS cluster module](link_to_commit_6)

6. **Define Azure Resources for AKS Cluster Configuration:** We defined the necessary Azure resources within the `main.tf` configuration file of the `aks-cluster-module`. These resources include the AKS cluster, node pool, and service principal. [See the wiki page for more details.](link_to_wiki_page_7)
   - Relevant commit: [devops-06: Define Azure resources for AKS cluster in Terraform configuration](link_to_commit_7)

7. **AKS Cluster Outputs Definition:** We defined output variables within the `outputs.tf` configuration file of the `aks-cluster-module`. These output variables capture essential information about the provisioned AKS cluster. [See the wiki page for more details.](link_to_wiki_page_8)
   - Relevant commit: [devops-07: Define output variables for AKS cluster module in Terraform configuration](link_to_commit_8)
     
8. **Full Automation of AKS Cluster Deployment:** Finally, we achieved full automation of the AKS cluster deployment using Terraform and Azure CLI. This includes provisioning infrastructure, managing secrets with Azure Key Vault, and handling errors gracefully. [See the wiki page for more details on full automation of AKS cluster deployment.](link_to_wiki_page_8)
   - Relevant commit: [devops-08: Full automation of AKS cluster deployment](link_to_commit_8)

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
  - `devops-08`: Full automation of AKS cluster deployment
- `feature-01`: This branch was used for adding the delivery date feature to the application.

Each task was developed in its respective branch and then merged into the `main` branch upon completion.
## Contributors 

- [Maya Iuga]([https://github.com/yourusername](https://github.com/maya-a-iuga))

## License

This project is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.
