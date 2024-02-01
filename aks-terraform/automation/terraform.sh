# Function to delete Terraform files in specified directories
function delete_terraform_files() {
  # Check for any running Terraform processes.
  local terraform_pid=$(pgrep terraform)
  if [ -n "$terraform_pid" ]; then
    echo "Terraform is currently running with PID: $terraform_pid"
    echo "Please wait for it to finish or terminate the process before attempting to delete files."
    return 1
  fi

  # Warn the user about the irreversible action of deleting files.
  echo "WARNING: This will permanently delete all Terraform configuration files in the specified directories."
  
  # Prompt for user confirmation before proceeding.
  read -p "Are you sure you want to continue? There is NO undo! [yes/no]: " confirm_delete
  
  if [[ $confirm_delete =~ ^[Yy] ]]; then
    # Define the directories where Terraform files are located.
    local module_dirs=("." "aks-cluster-module" "networking-module")

    # Loop through each directory and delete .tf files.
    for dir in "${module_dirs[@]}"; do
      if [ -d "$dir" ]; then
        echo "Deleting .tf files in $dir..."
        rm -f "$dir"/*.tf
      else
        echo "Directory $dir does not exist."
      fi
    done

    # Delete .tf files in the current directory.
    echo "Deleting .tf files in the current directory..."
    rm -f ./*.tf

    echo "File deletion complete."
  else
    echo "File deletion cancelled by user."
  fi
}

# Function to import multiple resources into Terraform state and reapply the plan.
import_resource() {
  # Accept two strings of space-separated resource IDs and addresses as input
  local resources_ids_combined=$1
  local -a resource_ids=($resources_ids_combined) # Split IDs into an array
  local resources_addresses_combined=$2
  local -a resource_addresses=($resources_addresses_combined) # Split addresses into an array

  # Check that the number of resource IDs matches the number of addresses
  if [ "${#resource_ids[@]}" -ne "${#resource_addresses[@]}" ]; then
    echo "Error: The number of resource IDs and addresses do not match."
    return 1
  fi

# Loop through each resource ID and corresponding address
  for ((i = 0; i < ${#resource_ids[@]}; i++)); do
    local resource_address="${resource_addresses[i]}"
    local resource_id="${resource_ids[i]}"

    # Import the resource using Terraform import command
    echo "Importing $resource_id into the current Terraform state at address $resource_address..."
    if terraform import "$resource_address" "$resource_id"; then
      echo "Resource $resource_id imported successfully."
    else
      # If import fails, output error message and exit with status 1
      echo "Error importing the resource $resource_id at address $resource_address. Check the output above for details."
      return 1
    fi
  done
  
  # After all resources are imported, create a new Terraform plan
  echo "Re-planning with the newly imported resources..."
  local plan_filename_after_import="${plan_filename}-IMPORTED-$(generate_timestamp)"
  if terraform plan -out="tfplans/${plan_filename_after_import}"; then
    echo "Re-plan successful. Applying the plan..."

    # Apply the new plan using Terraform apply command
    if terraform apply "tfplans/${plan_filename_after_import}"; then
      echo "Apply completed successfully."
    else
      # If apply fails, output error message and exit with status 1
      echo "Error applying the plan. Check the output above for details."
      return 1
    fi
  else
    # If planning fails, output error message and exit with status 1
    echo "Error during re-plan. Check the output above for details."
    return 1
  fi
}

# Function to catch "resource exists" errors and extract resource information
function catch_resource_exists_error() {
  local line="${1}"
  #DEBUG
  #  local line1="${1}"
  #  local line2="${2}"
  #  local line=$line1
  #  local line+=$line2

  local address_regex='(?<=ID \")[^\"]+'
  local id_regex='(?<=with ).*?(?=,$)'

  if echo "$line" | grep -Pq "($id_regex|$address_regex)"; then
    local resource_id=$(echo "$line" | grep -oP "$id_regex")
    local resource_address=$(echo "$line" | grep -oP "$address_regex")
    
    # If both resource ID and address are extracted, echo them and return success
    if [[ -n $resource_id || -n $resource_address ]]; then
      echo $resource_id,$resource_address
      return 0
    else
     return 1  # Return failure if no resource ID or address is found
    fi
  fi
}

# Function to catch "plan is stale" errors
catch_plan_stale_error() {
  local line="${1}"
  local stale_plan_regex="│ Error: Saved plan is stale"

  if echo "$line" | grep -oP "$stale_plan_regex"; then
    # The plan is stale, handle the error as needed
    local plan_stale_found=$(echo "$line" | grep -oP "$stale_plan_regex")
    if [[ -n $plan_stale_found ]];then
      echo "$plan_stale_found"
      return 0
    else
      return 1 #Return failure if its not a plan is stale eror.
    fi
  fi
}

# Function to save resource_id and resource_address from a multiline error message
function save_resource_info() {
  local result=$1
  local resource_id_tmp=""
  local resource_address_tmp=""

  if [[ -n $2 ]]; then
    local -n _resource_id=$2
  else
    echo "Error: Missing argument for resource ID"
    return 1 # Or handle the error as appropriate
  fi

  if [[ -n $3 ]]; then
    local -n _resource_address=$3
  else
    echo "Error: Missing argument for resource address"
    return 1 # Or handle the error as appropriate
  fi

  if [[ -n $result ]]; then
    IFS=',' read -r resource_id_tmp resource_address_tmp <<< $result
  fi

  # Record findings if resource_address or resource_id are set
  if [[ -n $resource_address_tmp ]]; then  
    echo "Resource Address: $resource_address_tmp"
    _resource_address=$resource_address_tmp
  fi
  if [[ -n $resource_id_tmp ]]; then  
    echo "Resource ID: $resource_id_tmp"
    _resource_id=$resource_id_tmp
  fi
}

# Initializes Terraform and creates a new plan with retries on failure and exponential backoff.
function terraform_init_and_plan() {
  local retries=3        # Number of times to retry initialization
  local delay=5          # Initial delay in seconds before first retry


  # Attempt to initialize Terraform with retries and exponential backoff
  for ((i=0; i<retries; i++)); do
    echo "Initializing the Terraform project configuration..."
    if terraform init; then
      echo "Terraform initialization successful."
     # Generate a new plan filename since the previous plan is stale.
      break  # Exit loop if successful
    else
      echo "An error occurred during Terraform init."
      if [[ $i -lt $((retries-1)) ]]; then
        echo "Retrying in $delay seconds..."
        sleep $delay  # Wait before retrying
        delay=$((delay*2))  # Double the delay for the next retry
      else
        echo "Failed to initialize Terraform after $retries attempts."
        return 1  # Return failure if all retries are exhausted
      fi
    fi
  done

  # Create a directory for plan files if it doesn't exist
  echo "Planning the Terraform project configuration ($plan_filename)..."
  if [ ! -d "tfplans" ]; then
    mkdir -p tfplans
    chown "$(whoami)":"$(whoami)" tfplans  # Set ownership of the directory
  fi
  plan_filename=$(generate_plan_filename)
  echo "New plan will be saved as 'tfplans/$plan_filename'"

  if terraform plan -out="tfplans/${plan_filename}"; then
    echo "Terraform plan was created successfully."
  else
    echo "Failed to create Terraform plan."
    return 1  # Return failure if unable to create a plan
  fi
}

# This function processes the standard error stream from Terraform commands.
# Applies Terraform plan, retries on resolved errors, or exits loop on unrecoverable errors.
function handle_terraform_errors() {
  local error_output="$(</dev/stdin)"  # Capture all input from stdin into error_output
  
  # Process the error_output line by line to handle the ressource exist error
  while IFS= read -r line; do
    # Check if the error_output contains a "resource already exists" error
    local resource_exists_error=$(catch_resource_exists_error "${error_output}")

    # If a resource already exists, attempt to import it
    if [[ -n $resource_exists_error ]]; then
      echo "WARNING: Resource already exists in Azure, attempting to solve..."
      save_resource_info "$resource_exists_error" resource_id resource_address
      if import_resource "$resource_address" "$resource_id"; then
        echo "Resource imported successfully."
        return 2  # Signal to retry the apply with a new plan
      else
        echo "Failed to import resource."
        return 1
      fi
    fi
  done <<< "$error_output"

  # Check if the error_output contains a "plan is stale" error
  if catch_plan_stale_error "${error_output}"; then
    echo "WARNING: Plan is stale, reinitializing and re-planning..."
    terraform_init_and_plan
    return 2  # Signal to retry the apply with a new plan
  fi

  return 0  # No actionable error was found
}

# Function to apply a Terraform plan and handle errors using the handle_terraform_errors function.
# USAGE: apply_terraform_plan "your_plan_file_name_here"
function apply_terraform_plan_and_handle_errors() {
  local exit_code=1
  local terraform_output
  local lock_id

  until [ "$exit_code" -eq 0 ]; do
    echo "Applying 'tfplans/$plan_filename' ..."

    # Check for a state lock before applying
    lock_id=$(terraform state list 2>&1 | grep -oP "(?<=ID: ).*")
    if [ -n "$lock_id" ]; then
      echo "Terraform state is locked by another process. Lock ID: $lock_id"
      echo "Attempting to unlock the state..."
      terraform force-unlock "$lock_id"
    fi

    # Run terraform apply, capturing both exit code and stderr
    terraform_output=$(terraform apply "tfplans/$plan_filename" 2>&1)
      #DEBUG:
      #terraform_output="│ Error: Saved plan is stale"
      #terraform_output="│   with module.networking.azurerm_network_security_group.nsg,"
      #terraform_output+=$'\n'
      #terraform_output+='A resource with the ID "/subscriptions/0ea57f0a-34c8-47e6-b1ac-cc3e1b5b244f/resourceGroups/networking-rg/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/worker-node-subnet"'
      #exit_code=1
    exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
      echo "An error occurred during Terraform apply:"
      echo "$terraform_output"
      echo "Attempting to resolve..."

      # Call handle_terraform_errors with the captured stderr as input
      handle_terraform_errors <<< "${terraform_output}"
      
      # Update exit_code in case handle_terraform_errors resolved the issue
      exit_code=$?
      
      # Check if a retry is needed (specific exit code 2 from handle_terraform_errors)
      if [ "$exit_code" -eq 2 ]; then
        echo "Retrying Terraform apply after handling errors..."
                
        # Reset exit_code to force another iteration of the loop
        exit_code=1
        continue  # Continue the loop to retry apply with the new plan
      else
        echo "No actionable error was found or an unrecoverable error occurred, stopping apply..."
        break
      fi
    else
      echo "Terraform apply completed successfully."
      exit_code=0
    fi
  done
}