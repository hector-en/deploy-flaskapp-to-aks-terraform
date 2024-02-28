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
#     if ! perform_operation_with_retry "./setup-aks-module.sh $TF_ENV"; then exit 1; fi
# 
#     # To call a function with arguments
#     if ! perform_operation_with_retry "your_function_name '$arg1' '$arg2'"; then exit 1; fi

perform_operation_with_retry() {
    local command_str=$1
    local max_attempts=${2:-2}
    local attempt_delay=5
    local attempt_count=0
    local output

    while [ $attempt_count -lt $max_attempts ]; do
        echo "Attempting operation: $command_str (Attempt #$((attempt_count + 1)) of $max_attempts)..."

        # Evaluate the command string and capture both stdout and stderr
        output=$(eval "$command_str" 2>&1)
        local status=$?

        if [ $status -eq 0 ]; then
            echo "Operation completed successfully."
            return 0
        else
            echo "Attempt #$((attempt_count + 1)) failed with error: $output"
            echo "Retrying in $attempt_delay seconds..."
            ((attempt_count++))
            sleep $attempt_delay
            # Exponential backoff: double the delay for the next attempt
            attempt_delay=$((attempt_delay * 2))
        fi
    done

    echo "Failed to complete operation after $max_attempts attempts."
    echo "Last error: $output"
    return 1
}
