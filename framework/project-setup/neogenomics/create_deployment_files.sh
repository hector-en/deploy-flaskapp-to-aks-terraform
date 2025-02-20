#!/bin/bash

# Filename: create-deployment-files.sh
# Purpose: Generates root Terraform configuration files for AKS and network deployment.

# Source automation scripts
source "$SCRIPTS_DIR/libraries/file-utilities.sh" || { echo "Failed to source $SCRIPTS_DIR/libraries/file-utilities.sh"; exit 1; }
source "$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }

#source "$SCRIPTS_DIR/cluster-management/cluster-output.sh" || { echo "Failed to source $SCRIPTS_DIR/cluster-management/cluster-output.sh"; exit 1; }
# environment dependent tag for deployment
#TESTING_TAG="${K8S_ENV^^}testing"              
#STAGING_TAG="${K8S_ENV^^}staging"              
#PRODUCTION_TAG="${K8S_ENV^^}production"              

# Define the heredoc content for terraform.tfvars as a string
read -r -d '' deploy_content <<EOF || true
#!/bin/bash
# Environment-specific deployment.
# Usage: ./deploy.sh <environment>
# Filename: deploy.sh
# Purpose: Deploys Kubernetes resources using Kustomize or Helm.


# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if PROJECT_ROOT is set. If not, set it using the Git repository root.
if [ -z "\$PROJECT_ROOT" ]; then
  export PROJECT_ROOT=\$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: \$PROJECT_ROOT."

# Source cluster configuration scripts.
source "\$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || {
  echo -e "\${RED}Failed to source cluster-config.sh\${NC}"
  exit 1
}
# Check if the environment parameter is provided and is valid.
if [ -z "\$1" ]; then
  echo -e "\${RED}Error: No environment specified.\${NC}"
  echo -e "\${YELLOW}Usage: \$0 <environment>\${NC}"
  echo -e "\${YELLOW}Valid options are: \${PROJECT_ENVIRONMENTS[*]}\${NC}"
  exit 1
fi

ENVIRONMENT=\$1
# Navigate to the Terraform directory
pushd "\$TF_ENV_DIR/" || exit
switch_to_workspace "\${ENVIRONMENT}" || exit 1
# Source the outputs from Terraform to get AKS cluster and resource group names.
source "\$PROJECT_ROOT/framework/cluster-management/cluster-output.sh" || {
  echo -e "\${RED}Failed to source cluster-output.sh\${NC}"
  exit 1
}

# Deploy Kubernetes resources using Kustomize or Helm.
if [ -d "\$PROJECT_ROOT/kubernetes/overlays/\$ENVIRONMENT" ]; then
  # Using Kustomize.
  configure_kubectl \$CURRENT_AKS_CLUSTER_NAME
  kubectl apply -k \$PROJECT_ROOT/kubernetes/overlays/\$ENVIRONMENT
elif [ -f "\$PROJECT_ROOT/kubernetes/overlays/helm/values-\${ENVIRONMENT}.yaml" ]; then
  # Using Helm.
  helm upgrade --install my-release my-chart/ -f "\$PROJECT_ROOT/kubernetes/overlays/helm/values-\${ENVIRONMENT}.yaml"
else
  echo "No Kubernetes overlay found for environment: \$ENVIRONMENT."
  exit 1
fi

# Check if the deployment actually needs an update
CURRENT_IMAGE=\$(kubectl get deployment flask-app-deployment -n \$ENVIRONMENT -o jsonpath='{.spec.template.spec.containers[0].image}')
LATEST_IMAGE="edunseng/my-flask-webapp:latest"

if [[ "\$CURRENT_IMAGE" != "\$LATEST_IMAGE" ]]; then
  echo -e "\${GREEN}🔄 New image detected! Updating deployment...\${NC}"
  kubectl set image deployment/flask-app-deployment flask-app-container=\$LATEST_IMAGE -n \$ENVIRONMENT
else
  echo -e "\${YELLOW}\✅ No new image detected. Skipping restart.\${NC}"
fi

verify_deployment "\$CURRENT_AKS_CLUSTER_NAME" "\$ENVIRONMENT" "flask-app-service" "flask-app-deployment"

# Check for external IP before port-forwarding
EXTERNAL_IP=\$(kubectl get svc flask-app-service -n \$ENVIRONMENT -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [[ -n "\$EXTERNAL_IP" ]]; then
  echo -e "\${GREEN}✅ App is accessible at: http://\$EXTERNAL_IP:5000\${NC}"
else
  echo -e "\${YELLOW}⚠️ No external IP found! Starting port-forwarding...\${NC}"
  LOCAL_PORT=5000
  REMOTE_PORT=5000
  POD_SELECTOR="app=flask-app"
  start_port_forwarding "\$LOCAL_PORT" "\$REMOTE_PORT" "\$POD_SELECTOR"
fi
popd # Return to the original directory.
EOF

# Define the heredoc content for autodeploy.tfvars as a string
read -r -d '' rollout_content <<EOF || true
#!/bin/bash
# Environment-specific Rollout.
# Usage: ./rollout.sh <environment|plan>

# Define ANSI color codes for colored output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if PROJECT_ROOT is set. If not, set it using the Git repository root.
if [ -z "\$PROJECT_ROOT" ]; then
  export PROJECT_ROOT=\$(git rev-parse --show-toplevel)
fi
echo "PROJECT_ROOT: \$PROJECT_ROOT."
source "\$PROJECT_ROOT/framework/cluster-management/cluster-config.sh" || { echo "Failed to source cluster-config.sh"; exit 1; }

# Check if the environment parameter is provided and is valid.
if [ -z "\$1" ]; then
  echo -e  "\${YELLOW}Usage: \$0 < \${PROJECT_ENVIRONMENTS[*]} | Plan >\${NC}"
  exit 1
elif ! is_valid_environment "\$1" \${PROJECT_ENVIRONMENTS}; then
  echo -e "\${RED}Error: Invalid environment. Valid options are: \${PROJECT_ENVIRONMENTS[*]}\${NC}"
  exit 1
fi
ENVIRONMENT=\$1
confirm_error_handling

# Source cluster configuration scripts and automation helper scripts.
source "\$SCRIPTS_DIR/utilities/azure.sh" || { echo "Failed to source azure.sh"; exit 1; }
source "\$SCRIPTS_DIR/utilities/terraform.sh" || { echo "Failed to source terraform.sh"; exit 1; }
source "\$SCRIPTS_DIR/libraries/dialog-utilities.sh" || { echo "Failed to source dialog-utilities.sh"; exit 1; }

# Ensure necessary tools are installed.
ensure_jq_installed
ensure_kubectl_installed


# Check if the ENVIRONMENT variable matches the expected format.
regex_pattern="^tfplan-aks-webapp-[0-9]{8}-[0-9]{6}-[a-zA-Z]+$"
if [[ \$ENVIRONMENT =~ \$regex_pattern ]]; then
  deploy="existing_environmnt"
else
  deploy="new_environment"
fi

# Ensure the .plans folder exists to store terraform plans.
if [ ! -d "\$TF_PLANS_DIR" ]; then
    echo "Creating directory: \$TF_PLANS_DIR"
    mkdir -p "\$TF_PLANS_DIR" && chown "\$(whoami)":"\$(whoami)" "\$TF_PLANS_DIR"
fi


# Navigate to the Terraform directory
pushd "\$TF_ENV_DIR/" || exit

# Initialize Terraform
setup_env_vars
terraform init

# Select the Terraform workspace
terraform workspace select "\$ENVIRONMENT" || terraform workspace new "\$ENVIRONMENT"

  # Apply the Terraform configuration based on the deploy type
  case "\$deploy" in
    "existing_environment")
      # If the deploy type is 'plan', apply the saved plan file
      echo "Applying saved Terraform plan..."
      apply_argument="\$TF_PLANS_DIR/\$ENVIRONMENT"
      terraform show \$apply_argument
      confirm_plan_apply
      apply_terraform_plan_and_handle_errors \$apply_argument
      ;;
    "new_environment")       
    # If new environment, plan then apply using the .tfvars file
      # Run Terraform Plan
      max_attempts=3
      apply_argument="-var-file=\"\${ENVIRONMENT}.tfvars\""      
      plan_file="\$TF_PLANS_DIR/\$ENVIRONMENT.tfplan"
      echo "Running Terraform Plan for environment: \$ENVIRONMENT..."
      # plan terraform environment with retries
      if ! perform_operation_with_retry "terraform plan -out='\$plan_file' \$apply_argument " \$max_attempts; then
        echo -e "\${RED}Error applying Terraform plan. Attempting to resolve...\${NC}"
      fi
      # if retry is unseccessfull exit at planning stage
      if [ \$? -ne 0 ]; then
      echo -e "\${RED}Terraform Plan failed. Please check the errors.\${NC}"
      exit 1
      fi
      # if planning successfull, save plan.
      echo "Terraform plan completed. Plan saved to \$plan_file."
      # Apply the plan file
      echo "Applying Terraform configuration with \$ENVIRONMENT.tfvars file..."
      apply_terraform_plan_and_handle_errors \$apply_argument
      ;;
    *)
      # Handle unexpected values of deploy
      echo -e "\${RED}Error: Unknown deployment type.\${NC}"
      exit 1
      ;;
  esac
# Verify and check the AKS cluster
switch_to_workspace "\${ENVIRONMENT}" || exit 1
# Check the rollout status of the deployment
check_rollout_status "flask-app-deployment"
verify_and_check_aks_cluster
# popd # Return to the original directory
EOF

# Function to create a tfvars file for a given environment.
create_tfvars() {
  local env=$1
  local tfvars_dir="$TF_ENV_DIR"
  local tfvars_file="${env}.tfvars"
  local tfvars_content_variable_name="${env}_content"
  local tfvars_content="${!tfvars_content_variable_name}"

  # Check if a specific content variable is provided for the environment.
  if [ -z "$tfvars_content" ]; then
    # No specific content provided, use the standard template.
    read -r -d '' tfvars_content <<EOF || true
# Standard Terraform settings template.

# AKS cluster configuration for the AKS module.
client_id       = "$TF_VAR_client_id"
client_secret   = "$TF_VAR_client_secret"
tenant_id       = "$TF_VAR_tenant_id"
subscription_id = "$TF_VAR_subscription_id"

# Activate this part, for testing only
#client_id       = "4508e9c8-4392-4475-a0b4-8dd3a9284d37"
#client_secret   = "M.o8Q~UqLKUSKxuEZVFR7LXKVuh4~GSARxdJ~adJ"
#tenant_id       = "63b5215c-c406-4ff6-b084-1a221a336dd0"
#subscription_id = "a272056f-85b6-4213-9e8b-8648c05f09e5"

aks_config = {
  cluster_name        = "aks-cluster-$TF_VAT_Project-$env",
  location            = "$TF_VAT_Location",
  resource_group_name = "aks-rg-$env",
  dns_prefix          = "$TF_VAT_Project-$env",
  kubernetes_version  = "1.18.14",
  tags                = {
    Environment = "$env",
    Project     = "$TF_VAT_Project",
    Owner       = "$TF_VAR_Owner"
  }
}

aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-$env",
    location = "$TF_VAT_Location",
    tags     = {
      Environment = "$env",
      Project     = "$TF_VAT_Project",
      Owner       = "$TF_VAR_Owner"
    }
  },
  vnet = {
    name           = "aks-vnet-$env",
    address_space  = ["10.10.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-$env",
      address_prefixes = ["10.10.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-$env",
      address_prefixes = ["10.10.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-$env",
    security_rules = [
      {
        name                       = "kube-apiserver-rule",
        priority                   = 1001,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "6443",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      },
      {
        name                       = "ssh-rule",
        priority                   = 1002,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "22",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      }
      // Additional security rules can be added here as needed.
    ]
  }
}
EOF
  fi

  # Create the tfvars file with the provided content.
  create_config_file "$tfvars_dir" "$tfvars_file" "$tfvars_content" || { echo "Failed to create $tfvars_dir/$tfvars_file"; exit 1; }
}


# Define the heredoc content for testing.tfvars as a string
read -r -d '' testing_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[0]}' environment.

# AKS cluster configuration for the AKS module.
client_id       = "$TF_VAR_client_id"
client_secret   = "$TF_VAR_client_secret"
tenant_id       = "$TF_VAR_tenant_id"
subscription_id = "$TF_VAR_subscription_id"

# AKS cluster configuration for testing only.
#client_id       = "4508e9c8-4392-4475-a0b4-8dd3a9284d37"
#client_secret   = "M.o8Q~UqLKUSKxuEZVFR7LXKVuh4~GSARxdJ~adJ"
#tenant_id       = "63b5215c-c406-4ff6-b084-1a221a336dd0"
#subscription_id = "a272056f-85b6-4213-9e8b-8648c05f09e5"

aks_config = {
  cluster_name        = "aks-cluster-$TF_VAT_Project-${PROJECT_ENVIRONMENTS[0]}",
  location            = "$TF_VAT_Location",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[0]}",
  dns_prefix          = "$TF_VAT_Project-${PROJECT_ENVIRONMENTS[0]}",
  kubernetes_version  = "1.18.14",
  tags                = {
    Environment = "${PROJECT_ENVIRONMENTS[0]}",
    Project     = "$TF_VAT_Project",
    Owner       = "$TF_VAR_Owner"
  }
}

aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-${PROJECT_ENVIRONMENTS[0]}",
    location = "$TF_VAT_Location",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[0]}",
      Project     = "$TF_VAT_Project",
      Owner       = "$TF_VAR_Owner"
    }
  },
  vnet = {
    name           = "aks-vnet-${PROJECT_ENVIRONMENTS[0]}",
    address_space  = ["10.10.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-${PROJECT_ENVIRONMENTS[0]}",
      address_prefixes = ["10.10.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-${PROJECT_ENVIRONMENTS[0]}",
      address_prefixes = ["10.10.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-${PROJECT_ENVIRONMENTS[0]}",
    security_rules = [
      {
        name                       = "kube-apiserver-rule",
        priority                   = 1001,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "6443",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      },
      {
        name                       = "ssh-rule",
        priority                   = 1002,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "22",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      }
    ]
  }
}
EOF

# Define the heredoc content for staging.tfvars as a string
read -r -d '' staging_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[1]}' environment.

# AKS cluster configuration for the AKS module.
client_id       = "$TF_VAR_client_id"
client_secret   = "$TF_VAR_client_secret"
tenant_id       = "$TF_VAR_tenant_id"
subscription_id = "$TF_VAR_subscription_id"

aks_config = {
  cluster_name        = "aks-cluster-$TF_VAT_Project-${PROJECT_ENVIRONMENTS[1]}",
  location            = "$TF_VAT_Location",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[1]}",
  dns_prefix          = "$TF_VAT_Project-${PROJECT_ENVIRONMENTS[1]}",
  kubernetes_version  = "1.19.7",
    tags              = {
    Environment = "${PROJECT_ENVIRONMENTS[1]}",
    Project     = "$TF_VAT_Project",
    Owner       = "$TF_VAR_Owner"
  }
}

# Network profile configuration for the AKS cluster.
aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-${PROJECT_ENVIRONMENTS[1]}",
    location = "$TF_VAT_Location",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[1]}",
      Project     = "$TF_VAT_Project",
      Owner       = "$TF_VAR_Owner"
    }
  },
  vnet = {
    name           = "aks-vnet-${PROJECT_ENVIRONMENTS[1]}",
    address_space  = ["10.20.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-${PROJECT_ENVIRONMENTS[1]}",
      address_prefixes = ["10.20.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-${PROJECT_ENVIRONMENTS[1]}",
      address_prefixes = ["10.20.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-${PROJECT_ENVIRONMENTS[1]}",
    security_rules = [
      {
        name                       = "kube-apiserver-rule",
        priority                   = 1001,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "6443",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      },
      {
        name                       = "ssh-rule",
        priority                   = 1002,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "22",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      }
    ]
  }
}
EOF

# Define the heredoc content for production.tfvars as a string
read -r -d '' production_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[2]}' environment.

# AKS cluster configuration for the AKS module.
client_id       = "$TF_VAR_client_id"
client_secret   = "$TF_VAR_client_secret"
tenant_id       = "$TF_VAR_tenant_id"
subscription_id = "$TF_VAR_subscription_id"

aks_config = {
  cluster_name        = "aks-cluster-$TF_VAT_Project-${PROJECT_ENVIRONMENTS[2]}",
  location            = "$TF_VAT_Location",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[2]}",
  dns_prefix          = "$TF_VAT_Project-${PROJECT_ENVIRONMENTS[2]}",
  kubernetes_version  = "1.20.5",
  tags                = {
    Environment = "${PROJECT_ENVIRONMENTS[2]}",
    Project     = "$TF_VAT_Project",
    Owner       = "$TF_VAR_Owner"
  }
}

# Network profile configuration for the AKS cluster.
aks_network_profile = {
  network_plugin = "azure",
  network_policy = "calico"
}

# AKS cluster configuration for the Network module.
network_infrastructure = {
  resource_group = {
    name     = "network-rg-${PROJECT_ENVIRONMENTS[2]}",
    location = "$TF_VAT_Location",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[2]}",
      Project     = "$TF_VAT_Project",
      Owner       = "$TF_VAR_Owner"
    }
  },
  vnet = {
    name           = "aks-vnet-${PROJECT_ENVIRONMENTS[2]}",
    address_space  = ["10.30.0.0/16"]
  },
  subnets = {
    control_plane_subnet = {
      name            = "control-plane-subnet-${PROJECT_ENVIRONMENTS[2]}",
      address_prefixes = ["10.30.1.0/24"]
    },
    worker_node_subnet = {
      name            = "worker-node-subnet-${PROJECT_ENVIRONMENTS[2]}",
      address_prefixes = ["10.30.2.0/24"]
    }
  },
  nsg = {
    name = "aks-nsg-${PROJECT_ENVIRONMENTS[2]}",
    security_rules = [
      {
        name                       = "kube-apiserver-rule",
        priority                   = 1001,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "6443",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      },
      {
        name                       = "ssh-rule",
        priority                   = 1002,
        direction                  = "Inbound",
        access                     = "Allow",
        protocol                   = "Tcp",
        source_port_range          = "*",
        destination_port_range     = "22",
        source_address_prefix      = "Internet",
        destination_address_prefix = "*"
      }
      // Additional security rules can be added here as needed.
    ]
  }
}
EOF

create_config_file "$PROJECT_ROOT" "deploy.sh" "$deploy_content" || { echo "Failed to create $$PROJECT_ROOT/kubernetes/deploy.sh"; exit 1; }
create_config_file "$PROJECT_ROOT" "rollout.sh" "$rollout_content" || { echo "Failed to create $$PROJECT_ROOT/kubernetes/rollout.sh"; exit 1; }

# make deploy.sh executable
chmod +x "$PROJECT_ROOT/deploy.sh"
chmod +x "$PROJECT_ROOT/rollout.sh"

# Iterate over each environment to create its tfvars file.
for env in "${PROJECT_ENVIRONMENTS[@]}"; do
  create_tfvars "$env"
done