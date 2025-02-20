#!/bin/bash
# Environment-specific deployment.
# Usage: ./deploy.sh <environment>
# Filename: deploy.sh
# Purpose: Deploys Kubernetes resources using Kustomize or Helm.


# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if PROJECT_ROOT is set. If not, set it using the Git repository root.
if [ -z "$PROJECT_ROOT" ]; then
  export PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: $PROJECT_ROOT."

# Source cluster configuration scripts.
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || {
  echo -e "${RED}Failed to source cluster-config.sh${NC}"
  exit 1
}
# Check if the environment parameter is provided and is valid.
if [ -z "$1" ]; then
  echo -e "${RED}Error: No environment specified.${NC}"
  echo -e "${YELLOW}Usage: $0 <environment>${NC}"
  echo -e "${YELLOW}Valid options are: ${PROJECT_ENVIRONMENTS[*]}${NC}"
  exit 1
fi

ENVIRONMENT=$1
# Navigate to the Terraform directory
pushd "$TF_ENV_DIR/" || exit
switch_to_workspace "${ENVIRONMENT}" || exit 1
# Source the outputs from Terraform to get AKS cluster and resource group names.
source "$PROJECT_ROOT/framework/cluster-management/cluster-output.sh" || {
  echo -e "${RED}Failed to source cluster-output.sh${NC}"
  exit 1
}

# Deploy Kubernetes resources using Kustomize or Helm.
if [ -d "$PROJECT_ROOT/kubernetes/overlays/$ENVIRONMENT" ]; then
  # Using Kustomize.
  configure_kubectl $CURRENT_AKS_CLUSTER_NAME
  kubectl apply -k $PROJECT_ROOT/kubernetes/overlays/$ENVIRONMENT
elif [ -f "$PROJECT_ROOT/kubernetes/overlays/helm/values-${ENVIRONMENT}.yaml" ]; then
  # Using Helm.
  helm upgrade --install my-release my-chart/ -f "$PROJECT_ROOT/kubernetes/overlays/helm/values-${ENVIRONMENT}.yaml"
else
  echo "No Kubernetes overlay found for environment: $ENVIRONMENT."
  exit 1
fi

# Check if the deployment actually needs an update
CURRENT_IMAGE=$(kubectl get deployment flask-app-deployment -n $ENVIRONMENT -o jsonpath='{.spec.template.spec.containers[0].image}')
LATEST_IMAGE="edunseng/my-flask-webapp:latest"

if [[ "$CURRENT_IMAGE" != "$LATEST_IMAGE" ]]; then
  echo -e "${GREEN}🔄 New image detected! Updating deployment...${NC}"
  kubectl set image deployment/flask-app-deployment flask-app-container=$LATEST_IMAGE -n $ENVIRONMENT
else
  echo -e "${YELLOW}\✅ No new image detected. Skipping restart.${NC}"
fi

verify_deployment "$CURRENT_AKS_CLUSTER_NAME" "$ENVIRONMENT" "flask-app-service" "flask-app-deployment"

# Check for external IP before port-forwarding
EXTERNAL_IP=$(kubectl get svc flask-app-service -n $ENVIRONMENT -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [[ -n "$EXTERNAL_IP" ]]; then
  echo -e "${GREEN}✅ App is accessible at: http://$EXTERNAL_IP:5000${NC}"
else
  echo -e "${YELLOW}⚠️ No external IP found! Starting port-forwarding...${NC}"
  LOCAL_PORT=5000
  REMOTE_PORT=5000
  POD_SELECTOR="app=flask-app"
  start_port_forwarding "$LOCAL_PORT" "$REMOTE_PORT" "$POD_SELECTOR"
fi
popd # Return to the original directory.
