#!/bin/bash

# Filename: create-k8s-files.sh
# Purpose: Creates base and overlay Kubernetes manifests and Kustomize configurations for AKS cluster setup across multiple environments.
# Usage: ./create-k8s-files.sh


# Source automation scripts for utility functions.
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/file-utilities.sh";  exit 1;}
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1;}

# Function to create base Kubernetes manifests and kustomization file.
create_base() {
  local base_dir=$1  # Pass the base directory as an argument.

  # Create the base kustomization.yaml file that references common resources.
  read -r -d '' base_kustomization_content <<EOF || true
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF
  create_config_file "$base_dir" "kustomization.yaml" "$base_kustomization_content"

  # Create the base deployment.yaml file with default settings.
  read -r -d '' base_deployment_content <<EOF || true
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app-deployment
spec:
  replicas: 1 # Default replica count for base configuration.
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app-container
        image: IMAGE_PLACEHOLDER # This will be replaced by Kustomize overlay.
        ports:
        - containerPort: 5000
EOF
  create_config_file "$base_dir" "deployment.yaml" "$base_deployment_content"

  # Create the base service.yaml file with default settings.
  read -r -d '' base_service_content <<EOF || true
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
spec:
  selector:
    app: flask-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000
  type: ClusterIP # Default service type for base configuration.
EOF
  create_config_file "$base_dir" "service.yaml" "$base_service_content"
}

# Create the base namespaces.yaml file defining namespaces for each environment.

# Directory where overlays will be stored
OVERLAYS_DIR="$PROJECT_ROOT/kubernetes/overlays"

# Function to create an overlay for a given environment.
create_overlay() {
  local env=$1
  local lower_env=$(echo "$env" | tr '[:upper:]' '[:lower:]') # Convert environment name to lowercase
  local overlay_dir="$OVERLAYS_DIR/$lower_env"

  # Create the overlay directory for the environment.
  mkdir -p "$overlay_dir" || { echo "Failed to create $overlay_dir"; exit 1; }

# Create the kustomization.yaml file for the environment specifying patches.
read -r -d '' overlay_kustomization_content <<EOF || true
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: $lower_env
resources:
- ../../base
- namespace.yaml
patches:
- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: flask-app-deployment
- path: service-patch.yaml
  target:
    kind: Service
    name: flask-app-service
EOF
create_config_file "$overlay_dir" "kustomization.yaml" "$overlay_kustomization_content"

# Create a deployment-patch.yaml file to customize the deployment for the environment.
read -r -d '' overlay_deployment_patch_content <<EOF || true
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app-deployment
  labels:
    env: $lower_env
spec:
  template: #applies to pods
    metadata:
      labels:
        app: flask-app
        env: $lower_env
    spec:
      containers:
      - name: flask-app-container
        image: edunseng/my-flask-webapp:latest # Always pull the latest image
        imagePullPolicy: Always  # Force Kubernetes to always pull the latest image
        env:  # Define environment variables here
        - name: $lower_env
          value: "$lower_env"
        resources:
          # ✅ Added resource requests and limits
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF
create_config_file "$overlay_dir" "deployment-patch.yaml" "$overlay_deployment_patch_content"
  
# Create a Service-patch.yaml file to customize the service for the environment.
read -r -d '' overlay_service_patch_content <<EOF || true
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
  labels:
    env: $lower_env  # Environment label for the Service
spec:
  type: LoadBalancer # for external IP
  selector:
    app: flask-app
    env: $lower_env  # Selector to match pods with these labels
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000

EOF
create_config_file "$overlay_dir" "service-patch.yaml" "$overlay_service_patch_content"


# Create the namespace.yaml file for the environment.
read -r -d '' namespace_content <<EOF || true
apiVersion: v1
kind: Namespace
metadata:
  name: $lower_env
EOF
create_config_file "$overlay_dir" "namespace.yaml" "$namespace_content"

}


# Call the create_base function with the path to the base directory.
create_base "$BASE_DIR"

# Iterate over each environment to create its overlay.
for env in "${PROJECT_ENVIRONMENTS[@]}"; do
  create_overlay "$env"
done

echo "Kubernetes base and environment overlays have been created successfully."