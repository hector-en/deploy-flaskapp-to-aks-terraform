#!/bin/bash

# Filename: setup-kubernetes-namespaces.sh
# Purpose: Creates Kubernetes namespaces as part of the AKS cluster setup process.
# Usage: ./setup-kubernetes-namespaces.sh <terraform_environment> <kubernetes_namespace>

# Set the Terraform environment and Kubernetes namespace variables
TF_ENV=$1
K8S_ENV=${2:-$1}

# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo ""
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  echo "(Optional): namespaces for the '$K8S_ENV' environment:"
  awk '/name:/{print $2}' $K8S_FILES_DIR/namespaces.yaml

echo ""
echo "Usage: $0 <env> <env-namespace (optional)>"
exit 1
fi

# Source automation scripts
source "$AZURE_DEVOPS_SCRIPTS_DIR/lib/setupfile_functions.sh" || { echo "Failed to source $AZURE_DEVOPS_SCRIPTS_DIR/utilities/setupfiles.sh"; exit 1; }

# Define the directory paths for the Terraform environment and Kubernetes overlays


# Define the heredoc content for patch.yaml as a string
read -r -d '' patch_yaml_content <<EOF || true
# Environment-specific patches for $K8S_ENV
EOF

# Define the heredoc content for kustomization.yaml as a string
read -r -d '' kustomization_yaml_content <<EOF || true
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
EOF

# Define the heredoc content for iitial namespaces.yaml as a string
read -r -d '' namespaces_yaml_content <<EOF || true
# testing-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: testing
---
# staging-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
# production-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF

# Define the heredoc content for tf_namespaces.yaml as a string
read -r -d '' tf_namespace_yaml_content <<EOF || true
apiVersion: v1
kind: Namespace
metadata:
  name: $K8S_ENV
EOF

# Call the function to create the files with the provided content
create_config_file "$K8S_FILES_DIR" "patch.yaml" "$patch_yaml_content" || { echo "Failed to create $K8S_FILES_DIR/patch.yaml.tf"; exit 1; }
create_config_file "$K8S_FILES_DIR" "kustomization.yaml" "$kustomization_yaml_content" || { echo "Failed to create $K8S_FILES_DIR/kustomization.yaml"; exit 1; }

# Create namespaces.yaml if it doesn't exist
if [ ! -f "$K8S_FILES_DIR/namespaces.yaml" ]; then
  create_config_file "$K8S_FILES_DIR" "namespaces.yaml" "$namespaces_yaml_content" || {  echo "Failed to create $K8S_FILES_DIR/namespaces.yaml"; exit 1;}
fi

# Check if the tf envronmnet already exists in the namespace.yaml file
if ! grep -q "name: $K8S_ENV" "$K8S_FILES_DIR/namespaces.yaml"; then
  # Append a tf environment as new namespace definition to the namespaces.yaml file in the environment-specific overlay directory
  append_to_file "$K8S_FILES_DIR" "namespaces.yaml" "$tf_namespace_yaml_content"
fi



