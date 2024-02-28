# Environment-specific deployment: TF('Tf_Staging')| K8S ($ENVIRONMENT).
#!/bin/bash

# Usage: ./deploy.sh <testing|staging|production> (default:testing)
ENVIRONMENT=${1:-"default"}

# Check if the environment parameter is p)rovided
if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <testing|staging|production> (default:testing)"
  exit 1
fi

# Navigate to the Terraform directory
pushd /home/vmuser/aicore/AiCoreDevOpsCapstone/terraform/environments/Tf_Staging/

# Initialize Terraform
terraform init

# Select the Terraform workspace
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

# Apply the Terraform configuration for the environment
terraform apply -var-file="${ENVIRONMENT}.tfvars"

popd

# Navigate to the Kubernetes directory
pushd /home/vmuser/aicore/AiCoreDevOpsCapstone/kubernetes/overlays/Tf_Staging/

# Deploy Kubernetes resources using Kustomize or Helm
if [ -d "overlays/Tf_Staging" ]; then
  # Using Kustomize
  kubectl apply -k "overlays/Tf_Staging"
elif [ -f "helm/values-${ENVIRONMENT}.yaml" ]; then
  # Using Helm
  helm upgrade --install my-release my-chart/ -f "helm/values-${ENVIRONMENT}.yaml"
else
  echo "No Kubernetes configuration found for environment: $ENVIRONMENT"
  exit 1
fi

popd
