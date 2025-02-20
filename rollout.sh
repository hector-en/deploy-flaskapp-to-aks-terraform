#!/bin/bash
# Environment-specific Rollout.
# Usage: ./rollout.sh <environment|plan>

# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if PROJECT_ROOT is set. If not, set it using the Git repository root.
if [ -z "$PROJECT_ROOT" ]; then
  export PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: $PROJECT_ROOT."
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }

# Check if the environment parameter is provided and is valid.
if [ -z "$1" ]; then
  echo -e  "${YELLOW}Usage: $0 < ${PROJECT_ENVIRONMENTS[*]} | Plan >${NC}"
  exit 1
elif ! is_valid_environment "$1" ${PROJECT_ENVIRONMENTS}; then
  echo -e "${RED}Error: Invalid environment. Valid options are: ${PROJECT_ENVIRONMENTS[*]}${NC}"
  exit 1
fi
ENVIRONMENT=$1
confirm_error_handling

# Source cluster configuration scripts and automation helper scripts.
source "$SCRIPTS_DIR/utilities/azure.sh" || { echo "Failed to source azure.sh"; exit 1; }
source "$SCRIPTS_DIR/utilities/terraform.sh" || { echo "Failed to source terraform.sh"; exit 1; }
source "$SCRIPTS_DIR/libraries/dialog-utilities.sh" || { echo "Failed to source dialog-utilities.sh"; exit 1; }

# Ensure necessary tools are installed.
ensure_jq_installed
ensure_kubectl_installed


# Check if the ENVIRONMENT variable matches the expected format.
regex_pattern="^tfplan-aks-webapp-[0-9]{8}-[0-9]{6}-[a-zA-Z]+$"
if [[ $ENVIRONMENT =~ $regex_pattern ]]; then
  deploy="existing_environmnt"
else
  deploy="new_environment"
fi

# Ensure the .plans folder exists to store terraform plans.
if [ ! -d "$TF_PLANS_DIR" ]; then
    echo "Creating directory: $TF_PLANS_DIR"
    mkdir -p "$TF_PLANS_DIR" && chown "$(whoami)":"$(whoami)" "$TF_PLANS_DIR"
fi


# Navigate to the Terraform directory
pushd "$TF_ENV_DIR/" || exit

# Initialize Terraform
setup_env_vars
terraform init

# Select the Terraform workspace
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

  # Apply the Terraform configuration based on the deploy type
  case "$deploy" in
    "existing_environment")
      # If the deploy type is 'plan', apply the saved plan file
      echo "Applying saved Terraform plan..."
      apply_argument="$TF_PLANS_DIR/$ENVIRONMENT"
      terraform show $apply_argument
      confirm_plan_apply
      apply_terraform_plan_and_handle_errors $apply_argument
      ;;
    "new_environment")       
    # If new environment, plan then apply using the .tfvars file
      # Run Terraform Plan
      max_attempts=3
      apply_argument="-var-file=\"${ENVIRONMENT}.tfvars\""      
      plan_file="$TF_PLANS_DIR/$ENVIRONMENT.tfplan"
      echo "Running Terraform Plan for environment: $ENVIRONMENT..."
      # plan terraform environment with retries
      if ! perform_operation_with_retry "terraform plan -out='$plan_file' $apply_argument " $max_attempts; then
        echo -e "${RED}Error applying Terraform plan. Attempting to resolve...${NC}"
      fi
      # if retry is unseccessfull exit at planning stage
      if [ $? -ne 0 ]; then
      echo -e "${RED}Terraform Plan failed. Please check the errors.${NC}"
      exit 1
      fi
      # if planning successfull, save plan.
      echo "Terraform plan completed. Plan saved to $plan_file."
      # Apply the plan file
      echo "Applying Terraform configuration with $ENVIRONMENT.tfvars file..."
      apply_terraform_plan_and_handle_errors $apply_argument
      ;;
    *)
      # Handle unexpected values of deploy
      echo -e "${RED}Error: Unknown deployment type.${NC}"
      exit 1
      ;;
  esac
  ;;
# Verify and check the AKS cluster
switch_to_workspace "${ENVIRONMENT}" || exit 1
# Check the rollout status of the deployment
check_rollout_status "flask-app-deployment"
verify_and_check_aks_cluster
# popd # Return to the original directory
