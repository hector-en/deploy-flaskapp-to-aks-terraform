# Prompts the user with a matrix of options and reads their choice.
function prompt_user_options() {
  echo "Please enter a series of digits to configure your environment:"
  echo "----------------------------------------------------------------"
  echo "1 - Create a new Azure Keyvault and Service Principal"
  echo "2 - Re-create module files"
  
  if [ -f "$TF_PLANS_DIR/$1" ]; then
    echo "3 - Reinitialize the Terraform cluster"
    echo "----------------------------------------------------------------"
    echo "Plan: $1"
    echo "----------------------------------------------------------------"
    read -p "Hit 'Enter' to apply plan, input digits (e.g., '12') for options: " user_choices
  else
    echo "----------------------------------------------------------------"
    read -p "Press 'Enter' for new workflow, enter digits (e.g., '2') for options: " user_choices
    # Append option 3 by default if no plan file is found
    user_choices+="3"
  fi
}

# Prompts user for confirmation to apply a Terraform plan, returning 1 if they decline.
function confirm_plan_apply() {
    read -p "Are you sure you want to apply this Terraform plan? [yes/no]: " yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) echo "Apply cancelled by user."; $yn=""; return 1;;
        * ) :;;
    esac
  # If the user confirms, proceed with  apply command
  echo "Proceeding with terraform apply ..."
}

# Prompts user for confirmation to import an existing resource into Terraform state.
function confirm_resource_import() {
  echo "A resource with the specified ID already exists and needs to be imported into Terraform state."
    read -p "Do you want to proceed with importing the resource? [yes/no]: " yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) echo "Import cancelled by user."; $yn=""; return 1;;
        * ) :;;
    esac
  # If the user confirms, proceed with the import command
  echo "Proceeding with the import..."
}

# Prompts user for confirmation to verify the AKS cluster creation.
function confirm_aks_cluster_creation() {
    read -p "Have you verified that the AKS cluster was created successfully? [yes/no]: " yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) echo "Please verify the AKS cluster creation before proceeding.";$yn=""; return 1;;
        * ) :;;
    esac
}

# Main dialog function to present available plans and handle user selection
function present_plan_options_and_apply() {
  echo "Available Terraform plans in $TF_PLANS_DIR:"
  local plans=("$TF_PLANS_DIR"/$tfplan_prefix-*)
  local index=1

  for plan in "${plans[@]}"; do
    echo "[$index] $(basename "$plan")"
    ((index++))
  done
  echo "[q] Quit"
  echo " Maybe apply a different plan ?"
  read -p "Select a plan to apply or 'q' to quit: " selection
  if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#plans[@]}" ]; then
    export plan="${plans[$selection-1]}"
    echo "You have selected: $(basename "$plan")"
    return 2
  fi
  exit 1
}
