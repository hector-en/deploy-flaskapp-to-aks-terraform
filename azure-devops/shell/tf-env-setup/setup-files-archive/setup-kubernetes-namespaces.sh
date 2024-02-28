#!/bin/bash

# Filename: setup-kubernetes-namespaces.sh
# Purpose: Creates Kubernetes namespaces as part of the AKS cluster setup process.
# Usage: ./setup-kubernetes-namespaces.sh <terraform_environment> <kubernetes_namespace>

# Creates a configuration file for Terraform or Kubernetes in the specified directory.
# Usage: create_configuration_file <directory> <filename> <heredoc-content>
function create_config_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Write the content to the file
  echo "$file_content" > "$file_path"

  # Check if the file was created successfully
  if [ ! -f "$file_path" ]; then
    echo "Failed to create ${file_name} at ${file_dir}"
    return 1
  else
    echo "${file_name} created successfully at ${file_dir}"
    return 0
  fi
}

# Appends provided content to a file in the specified directory, verifying successful operation.
append_to_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Check if the file exists before attempting to append
  if [ ! -f "$file_path" ]; then
    echo "File ${file_name} does not exist at ${file_dir}"
    return 1
  fi

  # Append the content to the file
  echo "$file_content" >> "$file_path"

  # Verify that the file still exists after appending
  if [ ! -f "$file_path" ]; then
    echo "Failed to append to ${file_name} at ${file_dir}"
    return 1
  else
    echo "Content appended successfully to ${file_name} at ${file_dir}"
    return 0
  fi
}


# Set the Terraform environment and Kubernetes namespace variables
TF_ENV=$1
K8S_ENV=$2

# Check if a terraform environment name was provided
if [ -z "$1" ]; then
  echo ""
  echo "Available environments:"
  ls -l $TF_ENV_DIR | grep ^d | awk '{print $9}'
  echo "(Optional): namespaces for the '$TF_ENV' environment:"
  awk '/name:/{print $2}' $KN_OVERLAYS_DIR/$TF_ENV/namespaces.yaml

echo ""
echo "Usage: $0 <env> <env-namespace (optional)>"
exit 1
fi

# Define the directory paths for the Terraform environment and Kubernetes overlays
ENVIRONMENTS_DIR="${TF_ENV_DIR:?}/$TF_ENV"
KN_ENVIRONMENT_DIR="${KN_OVERLAYS_DIR:?}/$TF_ENV"

# Create KN_ENVIRONMENT_DIR if it doesn't exist
if [ ! -d "$KN_ENVIRONMENT_DIR" ]; then
  mkdir -p "$KN_ENVIRONMENT_DIR" || { echo "Failed to create $KN_ENVIRONMENT_DIR"; exit 1; }
  chown "$(whoami)" "$KN_ENVIRONMENT_DIR" || { echo "Failed to change ownership of $KN_ENVIRONMENT_DIR"; exit 1; }
fi

# Create namespaces.yaml if it doesn't exist
if [ ! -f "$KN_OVERLAYS_DIR/$TF_ENV/namespaces.yaml" ]; then
  touch "$KN_OVERLAYS_DIR/$TF_ENV/namespaces.yaml" || { echo "Failed to create $KN_OVERLAYS_DIR/$TF_ENV/namespaces.yaml"; exit 1; }
fi

# Define the heredoc content for patch.yaml as a string
read -r -d '' patch_yaml_content <<EOF || true
# Environment-specific patches for $TF_ENV
EOF

# Define the heredoc content for kustomization.yaml as a string
read -r -d '' kustomization_yaml_content <<EOF || true
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
EOF

# Define the heredoc content for namespaces.yaml as a string
read -r -d '' namespace_yaml_content <<EOF || true
---
apiVersion: v1
kind: Namespace
metadata:
  name: $K8S_ENV
EOF

# Call the function to create the files with the provided content
create_config_file "$KN_ENVIRONMENT_DIR" "kustomization.yaml" "$kustomization_yaml_content" || { echo "Failed to create $KN_ENVIRONMENT_DIR/kustomization.yaml"; exit 1; }
create_config_file "$KN_ENVIRONMENT_DIR" "patch.yaml" "$patch_yaml_content" || { echo "Failed to create $KN_ENVIRONMENT_DIR/patch.yaml.tf"; exit 1; }

# Check if the namespace already exists in the namespace.yaml file
if ! grep -q "name: $K8S_ENV" "$KN_OVERLAYS_DIR/$K8S_ENV/namespaces.yaml"; then
  # Append a namespace definition to the namespaces.yaml file in the environment-specific overlay directory
  append_to_file "$KN_OVERLAYS_DIR/$K8S_ENV" "namespaces.yaml" "$namespace_yaml_content"
fi

