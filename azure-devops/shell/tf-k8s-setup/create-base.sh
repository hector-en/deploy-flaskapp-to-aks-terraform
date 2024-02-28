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


# Define the heredoc content for deployment.yaml as a string
read -r -d '' deployment_content <<EOF || true
# This is the combined Kubernetes manifest file including both the Deployment and Service definitions.
# The Deployment part ensures that two replicas of the flask-app-container are running, using the image edunseng/my-flask-webapp:1.0.
# It also defines a RollingUpdate strategy for updating the pods with minimal downtime.
# The Service part creates an internal service within the AKS cluster named flask-app-service.
# It routes internal traffic on TCP port 80 to the targetPort 5000 on the pods labeled with app: flask-app.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app-deployment # The name of the deployment
  labels:
    app: flask-app # Label to identify the deployment
spec:
  replicas: 2 # Number of pod replicas
  selector:
    matchLabels:
      app: flask-app # This should match the label of the pods that are to be selected for this deployment
  template:
    metadata:
      labels:
        app: flask-app # Label attached to the pod, used by the service to target these pods
    spec:
      containers:
      - name: flask-app-container # Name of the container within the pod
        image: edunseng/my-flask-webapp:1.0 # The image to use for the container
        ports:
        - containerPort: 5000 # The port the container will listen on
  strategy:
    type: RollingUpdate # Strategy for updating pods
    rollingUpdate:
      maxUnavailable: 1 # Max number of pods that can be unavailable during update
      maxSurge: 1 # Max number of pods that can be created over the desired number of pods

---
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service # The name of the service
spec:
  selector:
    app: flask-app # Selector to find the pods this service will route traffic to
  ports:
  - protocol: TCP # Protocol used by the service
    port: 80 # Port that the service listens on
    targetPort: 5000 # Target port on the pod to forward traffic to
  type: ClusterIP # Type of service, ClusterIP exposes the service on a cluster-internal IP
EOF

  echo "Kubernetes manifest file has been created successfully."
}

# Call the function to create the Kubernetes manifest file
create_kubernetes_manifest