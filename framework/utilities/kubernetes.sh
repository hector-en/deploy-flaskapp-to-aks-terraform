# kubernetes.sh: Script containing functions for managing Kubernetes resources via kubectl and Azure CLI.
# Source the cluster configuration script to set environment variables
# source $PROJECT_ROOT/azure-devops/configs/cluster-config.sh
# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to verify the correct kubectl context
function verify_kubectl_context() {
  local expected_context=$1 # The expected context name to check against

  # Get the current context name
  local current_context=$(kubectl config current-context)

  # Check if the current context matches the expected context
  if [[ "$current_context" == "$expected_context" ]]; then
    echo "Verified: kubectl is using the correct context: $current_context"
  else
    echo "Error: kubectl context mismatch. Expected '$expected_context', but the current context is '$current_context'"
    return 1
  fi
}

# Function to configure kubectl to use AKS credentials based on Terraform outputs
function configure_kubectl() {
  EXPECTED_AKS_CONTEXT=$1
  # Use the Terraform output variables for resource group and AKS cluster name
  # set context
  kubectl config set-context $CURRENT_AKS_CLUSTER_NAME
  kubectl config use-context $CURRENT_AKS_CLUSTER_NAME

  # Retrieve the kubeconfig for the AKS cluster using Azure CLI
  az aks get-credentials --resource-group "$AKS_RESOURCE_GROUP_NAME" --name "$CURRENT_AKS_CLUSTER_NAME" --file "./kubeconfig_$CURRENT_AKS_CLUSTER_NAME" --overwrite-existing
  export KUBECONFIG="./kubeconfig_$CURRENT_AKS_CLUSTER_NAME"
                            
  # Verify the correct kubectl context before deploying
  if ! verify_kubectl_context "$EXPECTED_AKS_CONTEXT"; then
    echo "Exiting due to incorrect kubectl context."
    exit 1
  fi

}

# Function to check the rollout status of a Kubernetes deployment
function check_rollout_status() {
  local deployment_name=$1

  echo -e "${YELLOW}Checking rollout status for deployment: $deployment_name.${NC}"
  kubectl rollout status deployment/"$deployment_name"
}

# Function to initiate port forwarding to a local machine for the first pod matched by the selector
function start_port_forwarding() {
  local local_port=$1
  local remote_port=$2
  local pod_selector=$3

  # Get the name of the first pod with the specified label selector
  local pod_name=$(kubectl get pods --selector="$pod_selector" --output=jsonpath='{.items[0].metadata.name}')

  if [ -z "$pod_name" ]; then
    echo "Error: No pod found with selector '$pod_selector'."
    return 1
  fi

  echo "Starting port forwarding from local port $local_port to pod $pod_name on port $remote_port..."
  kubectl port-forward "$pod_name" "$local_port":"$remote_port"
  # Output instructions for local access and testing
}

# Function to access application within the cluster
function access_application() {
  local service_name=$1

  echo "Accessing application via service: $service_name"
  # Assuming the service exposes a NodePort or LoadBalancer IP
  local service_ip=$(kubectl get service "$service_name" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  local service_port=$(kubectl get service "$service_name" -o jsonpath='{.spec.ports[0].nodePort}')

  if [ -z "$service_ip" ]; then
    echo "Service IP not found. Is the service type LoadBalancer and has it finished provisioning?"
    return 1
  fi

  echo "Application can be accessed at http://$service_ip:$service_port"
}

# Function to monitor logs for a set of pods
function monitor_pod_logs() {
  local selector=$1

  echo "Monitoring logs for pods with selector: $selector"
  kubectl logs --selector="$selector" --follow
}

# Function to describe a Kubernetes resource
function describe_kubernetes_resource() {
  local resource_type=$1
  local resource_name=$2

  echo "Describing $resource_type: $resource_name"
  kubectl describe "$resource_type" "$resource_name"
}

# Function to verify the deployment of Kubernetes resources
# Example usage of the function:
# verify_deployment "my-aks-cluster" "my-namespace" "flask-app-service" "flask-app-deployment"
verify_deployment() {
  local cluster_name=$1
  local namespace=$2
  local service_name=$3
  local deployment_name=$4

  echo -e "${GREEN}Checking deployment status for resources in AKS cluster: $cluster_name...${NC}"

  # List all namespaces
  echo -e "${YELLOW}Available Namespaces:${NC}"
  kubectl get namespaces

  # Check if the service exists and describe it
  if kubectl get service "$service_name" --namespace "$namespace" &> /dev/null; then
    echo -e "${GREEN}Service '$service_name' details:${NC}"
    kubectl describe service "$service_name" --namespace "$namespace"
  else
    echo -e "${RED}Service '$service_name' not found in namespace '$namespace'.${NC}"
  fi

  # Check if the deployment exists and describe it
  if kubectl get deployment "$deployment_name" --namespace "$namespace" &> /dev/null; then
    echo -e "${GREEN}Deployment '$deployment_name' details:${NC}"
    kubectl describe deployment "$deployment_name" --namespace "$namespace"
  else
    echo -e "${RED}Deployment '$deployment_name' not found in namespace '$namespace'.${NC}"
  fi

  # Optionally, check the status of the pods in the deployment
  echo -e "${YELLOW}Pods status for deployment '$deployment_name':${NC}"
  kubectl get pods --namespace "$namespace" -l app="$service_name" # Adjust the label selector as needed
}

echo "Kubernetes deployment functions are now available."
