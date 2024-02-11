#!/bin/bash

# aks-kubernetes-solution1.sh: This script automates the creation of a Kubernetes manifest file for deploying a containerized web application onto an AKS cluster.
# The script generates an 'application-manifest.yaml' within the 'aks-kubernetes/config' directory, defining a Deployment resource named 'flask-app-deployment'.
# It ensures the deployment runs with two replicas for high availability and uses a RollingUpdate strategy for seamless updates.

# The manifest includes:
# - A Deployment resource named 'flask-app-deployment'
# - Two replicas of the application for scalability and high availability
# - Selector field with 'matchLabels' to identify pods managed by the Deployment
# - Metadata labels in the pod template to establish a connection between the pods and the managed application
# - Configuration to use a specific container image hosted on Docker Hub
# - Exposed port 5000 for intra-cluster communication
# - RollingUpdate strategy with parameters to maintain service availability during updates

# Usage:
# Execute this script to create the Kubernetes manifest file. No arguments are required.
# ./aks-kubernetes-solution1.sh

# Prerequisites:
# Ensure you have write permissions to the 'aks-kubernetes/config' directory before running this script.

# Output:
# The script will output the path to the created manifest file upon successful execution.

# Navigate to the 'aks-kubernetes/config' directory
MANIFEST_DIR="../config"

# Function to create the Kubernetes manifest file
create_kubernetes_manifest() {
  local manifest_file_path="$MANIFEST_DIR/application-manifest.yaml"

  echo "Creating Kubernetes manifest file at: $manifest_file_path"

  # Create the Kubernetes manifest content
  cat << EOF > "$manifest_file_path"
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