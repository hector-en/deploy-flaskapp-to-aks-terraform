#!/bin/bash

# Filename: setup-root-configuration.sh
# Purpose: Generates root Terraform configuration files for AKS and network deployment.

# Set the Terraform environment and Kubernetes namespace variables
TF_ENV=$1
K8S_ENV=${2:-$1}

# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo ""
  echo "Available environments:"
  ls -l $TF_EK8S_ENVNV_DIR | grep ^d | awk '{print $9}'
  echo "(Optional): namespaces for the '$K8S_ENV' environment:"
  awk '/name:/{print $2}' $K8S_OVERLAYS_DIR/$K8S_ENV/namespaces.yaml

echo ""
echo "Usage: $0 <env> <env-namespace (optional)>"
exit 1
fi

# Source automation scripts
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/utilities/setupfiles.sh"; exit 1; }
source "$AZURE_DEVOPS_CONFIG_DIR/cluster-output.sh" || { echo "Failed to source $AZURE_DEVOPS_CONFIG_DIR/cluster-output.sh"; exit 1; }

# environment dependent tag for deployment
TESTING_TAG="${K8S_ENV^^}testing"              
STAGING_TAG="${K8S_ENV^^}staging"              
PRODUCTION_TAG="${K8S_ENV^^}production"              

# Create directories if they don't exist
# Create ENVIRONMENTS_DIR if it doesn't exist
if [ ! -d "$K8S_FILES_DIR" ]; then
  mkdir -p "$K8S_FILES_DIR" || { echo "Failed to create $K8S_FILES_DIR"; exit 1; }
  chown "$(whoami)":"$(whoami)" "$K8S_FILES_DIR"  # Set ownership of the directory
fi

# Define the heredoc content for terraform.tfvars as a string
read -r -d '' deploy_content <<EOF || true
# Environment-specific deployment: TF('$TF_ENV')| K8S (\$ENVIRONMENT).
#!/bin/bash

# Usage: ./deploy.sh <testing|staging|production> (default:testing)
ENVIRONMENT=\${1:-"default"}

# Check if the environment parameter is p)rovided
if [ -z "\$ENVIRONMENT" ]; then
  echo "Usage: \$0 <testing|staging|production> (default:testing)"
  exit 1
fi

# Navigate to the Terraform directory
pushd $TF_ENV_FILES_DIR/

# Initialize Terraform
terraform init

# Select the Terraform workspace
terraform workspace select "\$ENVIRONMENT" || terraform workspace new "\$ENVIRONMENT"

# Apply the Terraform configuration for the environment
terraform apply -var-file="\${ENVIRONMENT}.tfvars"

popd

# Navigate to the Kubernetes directory
pushd $K8S_FILES_DIR/

# Deploy Kubernetes resources using Kustomize or Helm
if [ -d "overlays/$K8S_ENV" ]; then
  # Using Kustomize
  kubectl apply -k "overlays/$K8S_ENV"
elif [ -f "helm/values-\${ENVIRONMENT}.yaml" ]; then
  # Using Helm
  helm upgrade --install my-release my-chart/ -f "helm/values-\${ENVIRONMENT}.yaml"
else
  echo "No Kubernetes configuration found for environment: \$ENVIRONMENT"
  exit 1
fi

popd
EOF

# Define the heredoc content for default.tfvars as a string
read -r -d '' testing_content <<EOF || true
# Environment-specific Terraform settings - Terrafoem Environmen: '$K8S_ENV' | Kubernetes Namespace: $K8S_ENV
#aks_resource_group_name = $AKS_RESOURCE_GROUP_NAME--$K8S_ENV"
#network_resource_group_name =  $NETWORK_RESOURCE_GROUP_NAME--$K8S_ENV"
aks_cluster_name    = $CURRENT_AKS_CLUSTER_NAME--$K8S_ENV"
#vnet_address_space  = "10.10.0.0/16"
EOF

# Define the heredoc content for default.tfvars as a string
read -r -d '' testing_content <<EOF || true
# Environment-specific Terraform settings - Terrafoem Environmen: '$K8S_ENV' | Kubernetes Namespace: production
#aks_resource_group_name = $AKS_RESOURCE_GROUP_NAME--$TESTING_TAG"
#network_resource_group_name =  $NETWORK_RESOURCE_GROUP_NAME--$TESTING_TAG"
aks_cluster_name    = $CURRENT_AKS_CLUSTER_NAME--$TESTING_TAG"
#vnet_address_space  = "10.20.0.0/16"
EOF

# Define the heredoc content for staging.tfvars as a string
read -r -d '' staging_content <<EOF || true
# Environment-specific Terraform settings - Terrafoem Environmen: '$K8S_ENV' | Kubernetes Namespace: production
#aks_resource_group_name = $AKS_RESOURCE_GROUP_NAME--$STAGING_TAG"
#network_resource_group_name =  $NETWORK_RESOURCE_GROUP_NAME--$STAGING_TAG"
aks_cluster_name    = $CURRENT_AKS_CLUSTER_NAME--$STAGING_TAG"
#vnet_address_space  = "10.30.0.0/16"
EOF

# Define the heredoc content for production.tfvars as a string
read -r -d '' production_content <<EOF || true
# Environment-specific Terraform settings - Terrafoem Environmen: '$K8S_ENV' | Kubernetes Namespace: production
#aks_resource_group_name = $AKS_RESOURCE_GROUP_NAME--$PRODUCTION_TAG"
#network_resource_group_name =  $NETWORK_RESOURCE_GROUP_NAME--$PRODUCTION_TAG"
aks_cluster_name    = $CURRENT_AKS_CLUSTER_NAME--$PRODUCTION_TAG"
#vnet_address_space  = "10.40.0.0/16"
EOF

create_config_file "$KUBERNETES_DIR" "deploy.sh" "$deploy_content" || { echo "Failed to create $KUBERNETES_DIR/deploy.sh"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "$K8S_ENV.tfvars" "$K8S_ENV"+"_content" || { echo "Failed to create $TF_ENV_FILES_DIR/$K8S_ENV.tfvars"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "testing.tfvars" "$testing_content" || { echo "Failed to create $TF_ENV_FILES_DIR/testing.tfvars"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "staging.tfvars" "$staging_content" || { echo "Failed to create $TF_ENV_FILES_DIR/staging.tfvars"; exit 1; }
create_config_file "$TF_ENV_FILES_DIR" "production.tfvars" "$production_content" || { echo "Failed to create $TF_ENV_FILES_DIR/production.tfvars"; exit 1; }

# make deploy.sh executable
chmod +x "$KUBERNETES_DIR/deploy.sh"