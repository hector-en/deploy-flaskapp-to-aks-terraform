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
verify_deployment "\$CURRENT_AKS_CLUSTER_NAME" "\$ENVIRONMENT" "flask-app-service" "flask-app-deployment"
# Initiate port forwarding to access the application locally
LOCAL_PORT=5000
REMOTE_PORT=5000
POD_SELECTOR="app=flask-app"
start_port_forwarding "\$LOCAL_PORT" "\$REMOTE_PORT" "\$POD_SELECTOR"

popd # Return to the original directory.
EOF

# Define the heredoc content for autodeploy.tfvars as a string
read -r -d '' rollout_content <<EOF || true
# Environment-specific Rollout.

#!/bin/bash
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
  echo-e  "\${YELLOW}Usage: \$0 < \${PROJECT_ENVIRONMENTS[*]} | Plan >\${NC}"
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
  deploy="plan"
else
  deploy="environment"
fi

# Navigate to the Terraform directory
pushd "\$TF_ENV_DIR/" || exit

# Initialize Terraform
setup_env_vars
terraform init

# Select the Terraform workspace
terraform workspace select "\$ENVIRONMENT" || terraform workspace new "\$ENVIRONMENT"

case "\$error_handler" in
"on") 
  # Apply the Terraform configuration based on the deploy type
  case "\$deploy" in
    "plan")
      # If the deploy type is 'plan', apply the saved plan file
      echo "Applying saved Terraform plan..."
      apply_argument="\$TF_PLANS_DIR/\$ENVIRONMENT"
      terraform show \$apply_argument
      confirm_plan_apply
      apply_terraform_plan_and_handle_errors \$apply_argument
      ;;
    "environment")
      # If the deploy type is 'environment', apply using the .tfvars file
      echo "Applying Terraform configuration with \$ENVIRONMENT.tfvars file..."
      apply_argument="-var-file=\"\${ENVIRONMENT}.tfvars\""      
      apply_terraform_plan_and_handle_errors \$apply_argument
      ;;
    *)
      # Handle unexpected values of deploy
      echo -e "\${RED}Error: Unknown deployment type.\${NC}"
      exit 1
      ;;
  esac
  ;;
"off")
  # Apply the Terraform configuration based on the deploy type
  case "\$deploy" in
    "plan")
      # If the deploy type is 'plan', apply the saved plan file
      echo "Applying saved Terraform plan..."
      terraform show "\$TF_PLANS_DIR/\$ENVIRONMENT"
      confirm_plan_apply
      terraform apply "\$TF_PLANS_DIR/\$ENVIRONMENT"
      ;;
    "environment")
      # If the deploy type is 'environment', apply using the .tfvars file
      echo "Applying Terraform configuration with \$ENVIRONMENT.tfvars file..."
      terraform apply -var-file="\${ENVIRONMENT}.tfvars"
      ;;
    *)
      # Handle unexpected values of deploy
      echo "\${RED}Error: Unknown deployment type.\${NC}"
      exit 1
      ;;
  esac
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
# Delete this part, when using environment variables
client_id       = "4508e9c8-4392-4475-a0b4-8dd3a9284d37"
client_secret   = "M.o8Q~UqLKUSKxuEZVFR7LXKVuh4~GSARxdJ~adJ"
tenant_id       = "63b5215c-c406-4ff6-b084-1a221a336dd0"
subscription_id = "a272056f-85b6-4213-9e8b-8648c05f09e5"

aks_config = {
  cluster_name        = "aks-cluster-aicoretemp-$env",
  location            = "uksouth",
  resource_group_name = "aks-rg-$env",
  dns_prefix          = "aicoretemp-$env",
  kubernetes_version  = "1.18.14",
  tags                = {
    Environment = "$env",
    Project     = "my-flask-webapp",
    Owner       = "AicoreTemp"
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
    location = "UK South",
    tags     = {
      Environment = "$env",
      Project     = "$Project",
      Owner       = "$Owner"
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
read -r -d '' Training_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[0]}' environment.

# AKS cluster configuration for the AKS module.

client_id       = "4508e9c8-4392-4475-a0b4-8dd3a9284d37"
client_secret   = "M.o8Q~UqLKUSKxuEZVFR7LXKVuh4~GSARxdJ~adJ"
tenant_id       = "63b5215c-c406-4ff6-b084-1a221a336dd0"
subscription_id = "a272056f-85b6-4213-9e8b-8648c05f09e5"

aks_config = {
  cluster_name        = "aks-cluster-aicoretemp-${PROJECT_ENVIRONMENTS[0]}",
  location            = "uksouth",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[0]}",
  dns_prefix          = "aicoretemp-${PROJECT_ENVIRONMENTS[0]}",
  kubernetes_version  = "1.18.14",
  tags                = {
    Environment = "${PROJECT_ENVIRONMENTS[0]}",
    Project     = "$Project",
    Owner       = "$Owner"
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
    location = "UK South",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[0]}",
      Project     = "my-flask-webapp",
      Owner       = "AicoreTemp"
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
read -r -d '' Staging_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[1]}' environment.

# AKS cluster configuration for the AKS module.
aks_config = {
  cluster_name        = "aks-cluster-aicoretemp-${PROJECT_ENVIRONMENTS[1]}",
  location            = "ukwest",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[1]}",
  dns_prefix          = "aicoretemp-${PROJECT_ENVIRONMENTS[1]}",
  kubernetes_version  = "1.19.7",
    tags                = {
    Environment = "${PROJECT_ENVIRONMENTS[1]}",
    Project     = "my-flask-webapp",
    Owner       = "AicoreTemp"
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
    location = "UK West",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[1]}",
      Project     = "my-flask-webapp",
      Owner       = "AicoreTemp"
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
read -r -d '' Production_content <<EOF || true
# Terraform settings for the '${PROJECT_ENVIRONMENTS[2]}' environment.

# AKS cluster configuration for the AKS module.
aks_config = {
  cluster_name        = "aks-cluster-aicoretemp-${PROJECT_ENVIRONMENTS[2]}",
  location            = "uksouth",
  resource_group_name = "aks-rg-${PROJECT_ENVIRONMENTS[2]}",
  dns_prefix          = "aicoretemp-${PROJECT_ENVIRONMENTS[2]}",
  kubernetes_version  = "1.20.5",
  tags                = {
    Environment = "${PROJECT_ENVIRONMENTS[2]}",
    Project     = "$Project",
    Owner       = "$Owner"
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
    location = "UK South",
    tags     = {
      Environment = "${PROJECT_ENVIRONMENTS[2]}",
      Project     = "my-flask-webapp",
      Owner       = "AicoreTemp"
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