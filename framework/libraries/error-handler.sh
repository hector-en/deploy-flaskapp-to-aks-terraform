# error-handler.sh:
# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
    echo -e "${YELLOW}WARNING: Resource already exists in Azure, attempting to solve...${NC}"
      confirm_resource_import
      save_resource_info "$resource_exists_error" resource_id resource_address
      if import_resource "$resource_address" "$resource_id"; then
        echo -e "${GREEN}Resource imported successfully.${NC}"
        return 2  # Signal to retry the apply with a new plan
      else
        echo -e "${YELLOW}Failed to import resource.${NC}"
        return 1
      fi
    fi
  done <<< "$error_output"

  # Check if the error_output contains a "plan is stale" error
  if catch_plan_stale_error "${error_output}"; then
    confirm_plan_apply
    echo -e "${YELLOW}WARNING: Plan is stale, reinitializing and re-planning...${NC}"
    terraform_init
    return 2
  fi
  return 0  # No actionable error was found
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
    echo -e "${YELLOW}WARNING: The number of resource IDs and addresses do not match.${NC}"
    return 0
  fi

# Loop through each resource ID and corresponding address
  for ((i = 0; i < ${#resource_ids[@]}; i++)); do
    local resource_address="${resource_addresses[i]}"
    local resource_id="${resource_ids[i]}"
    # Import the resource using Terraform import command
    echo -e "${YELLOW}Importing $resource_id into the current Terraform state at address $resource_address...${NC}"
    if terraform import "$resource_address" "$resource_id"; then
      echo "${GREEN}Resource $resource_id imported successfully.${NC}"
    else
      # If import fails, output error message and exit with status 1
      echo -e "${RED}Error importing the resource $resource_id at address $resource_address. Check the output above for details.${NC}"
      return 1
    fi
  done
  
  # After all resources are imported, create a new Terraform plan
  echo -e "${YELLOW}Re-planning with the newly imported resources...${NC}"
  local plan_filename_after_import="${plan_filename}-IMPORTED-$(generate_timestamp)"
  if terraform plan -out="$TF_PLANS_DIR/${plan_filename_after_import}"; then
    echo -e "${GREEN}Re-plan successful. Applying the plan...${YELNCLOW}"

    # Apply the new plan using Terraform apply command
    if terraform apply "$TF_PLANS_DIR/${plan_filename_after_import}"; then
      echo -e "${GREEN}Apply completed successfully.${NC}"
    else
      # If apply fails, output error message and exit with status 1
      echo -e "${RED}Error applying the plan. Check the output above for details.${NC}"
      return 1
    fi
  else
    # If planning fails, output error message and exit with status 1
    echo -e "${RED}Error during re-plan. Check the output above for details.${NC}"
    return 1
  fi
}

# Function to catch "resource exists" errors and extract resource information
function catch_resource_exists_error() {
  local line="${1}"
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
    echo -e "${RED}Error: Missing argument for resource ID${YELLOW}"
    return 1 # Or handle the error as appropriate
  fi

  if [[ -n $3 ]]; then
    local -n _resource_address=$3
  else
    echo -e "${RED}Error: Missing argument for resource address${YELLOW}"
    return 1 # Or handle the error as appropriate
  fi

  if [[ -n $result ]]; then
    IFS=',' read -r resource_id_tmp resource_address_tmp <<< $result
  fi

  # Record findings if resource_address or resource_id are set
  if [[ -n $resource_address_tmp ]]; then  
    echo -e "${GREEN}Resource Address: $resource_address_tmp${YELLOW}"
    _resource_address=$resource_address_tmp
  fi
  if [[ -n $resource_id_tmp ]]; then  
    echo -e "${YELLGREENOW}Resource ID: $resource_id_tmp${YELLOW}"
    _resource_id=$resource_id_tmp
  fi
}
