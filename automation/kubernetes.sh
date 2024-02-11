# kubernetes.sh: Script containing functions for managing Kubernetes resources via kubectl and Azure CLI.

# Function to prompt user for Kubernetes deployment options
function prompt_kubernetes_deployment_options() {
  echo "Select an option for Kubernetes deployment:"
  echo "1 - Recreate deployment YAML files"
  # Add more options as needed
  echo "----------------------------------------------------------------"
  read -p "Press 'Enter' to start deployment, enter digits (e.g., '1') for options: " user_choices
}

# Function to delete all .yaml files in aks-kubernetes/config
function delete_kubernetes_yaml_files() {
  local kubernetes_config_dir="config"

  # Check if the directory exists
  if [ -d "$kubernetes_config_dir" ]; then
    echo "Deleting all .yaml files in $kubernetes_config_dir..."
    rm -f "$kubernetes_config_dir"/*.yaml
    echo "Deletion of .yaml files complete."
  else
    echo "Directory $kubernetes_config_dir does not exist."
    return 1
  fi
}

# Function to run all aks-kubernetes-solution scripts
function run_aks_kubernetes_solution_scripts() {
  local solutions_dir="solutions"

  # Change to the solutions directory
  pushd "$solutions_dir" > /dev/null

  # Execute each solution script
  ./aks-kubernetes-solution1.sh | { echo "Failed to create Kubernetes configuration files"; exit 1; }
  # Add additional solution script executions as needed

  # Return to the original directory
  popd > /dev/null
}


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

# Function to configure kubectl to use AKS credentials
function configure_kubectl() {
  local resource_group_name=$1
  local aks_cluster_name=$2

  echo "Fetching credentials for AKS cluster..."
  az aks get-credentials --resource-group $resource_group_name --name $aks_cluster_name --overwrite-existing
}

# Function to apply a Kubernetes manifest file
function apply_kubernetes_manifest() {
  local manifest_file=$1

  echo "Applying Kubernetes manifest: $manifest_file"
  kubectl apply -f "$manifest_file"
}

# Function to check the rollout status of a Kubernetes deployment
function check_rollout_status() {
  local deployment_name=$1

  echo "Checking rollout status for deployment: $deployment_name"
  kubectl rollout status deployment/"$deployment_name"
}

# Function to verify the status and details of pods within the AKS cluster
function verify_pods_status() {
  local pod_selector=$1

  echo "Verifying the status of pods with selector: $pod_selector..."
  kubectl get pods --selector="$pod_selector"
}

# Function to verify the status and details of a service within the AKS cluster
function verify_service_status() {
  local service_name=$1

  echo "Verifying the status and details of service: $service_name..."
  kubectl get service "$service_name"
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

# Function to recreate the Kubernetes files
function recreate_kubernetes_files() {
  local manifest_script="aks-kubernetes-solution1.sh"
  local solutions_dir="solutions"

  echo "Recreating the Kubernetes manifest file using $manifest_script..."

  if [ -f "$solutions_dir/$manifest_script" ]; then
    source "$solutions_dir/$manifest_script"
  else
    echo "Error: Manifest creation script not found in $solutions_dir"
    return 1
  fi
}

echo "Kubernetes deployment functions are now available."
