#!/bin/bash
# file-utilities.sh

# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Creates a configuration file for Terraform or Kubernetes in the specified directory.
# Usage: create_configuration_file <directory> <filename> <heredoc-content>
function create_config_file() {
  local file_dir=$1
  local file_name=$2
  local file_content=$3
  local file_path="${file_dir}/${file_name}"

  # Write the content to the file
  echo "$file_content" >| "$file_path"

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


# Function to perform a given setup operation with retry and exponential backoff
# Usage:
#     # To run a script with an environment variable
#     if ! perform_operation_with_retry "./setup-aks-module.sh"; then exit 1; fi
# 
#     # To call a function with arguments
#     if ! perform_operation_with_retry "your_function_name '$arg1' '$arg2'"; then exit 1; fi

# Function to perform a given setup operation with retry and exponential backoff
perform_operation_with_retry() {
    local command_str=$1
    local max_attempts=${2:-1}
    local attempt_delay=5
    local attempt_count=0

    # Use a temporary file to capture stderr
    local temp_file=$(mktemp)

    while [ $attempt_count -lt $max_attempts ]; do
        echo "Attempting operation: $command_str (Attempt #$((attempt_count + 1)) of $max_attempts)..."

        # Execute the command and redirect stderr to the temporary file while allowing stdout to be displayed
        eval "$command_str" 2> "$temp_file"
        local status=$?

        if [ $status -eq 0 ]; then
            echo "Operation completed successfully."
            # Clean up the temporary file
            rm "$temp_file"
            return 0
        else
            echo -e "${RED}Attempt #$((attempt_count + 1)) failed.${NC}"
            ((attempt_count++))
            sleep $attempt_delay
            # Exponential backoff: double the delay for the next attempt
            attempt_delay=$((attempt_delay * 2))
        fi
    done

    # Read the contents of the temporary file into terraform_output
    terraform_output=$(<"$temp_file")
    # Clean up the temporary file
    rm "$temp_file"
    return 1
}

# Function to check if the provided environment is valid.
is_valid_environment() {
  local env=$1
  local project_env=$2
  local regex_pattern="^tfplan-aks-webapp-[0-9]{8}-[0-9]{6}-[a-zA-Z]+$"

  for valid_env in "${project_env[@]}"; do
    if [[ "$env" == "$valid_env" ]]; then
      return 0 # This means the environment is valid.
    # Check if the ENVIRONMENT variable matches the expected format.
    elif [[ $env =~ $regex_pattern ]]; then
      return 0 # This means the environment is valid.
    fi
  done
  return 1 # No match found, invalid environment.
}
