Libraries Directory Overview
----------------------------

The 'libraries' directory contains a collection of shell scripts that provide utility functions for managing Azure resources, handling Terraform operations, and facilitating various file operations. These scripts are designed to abstract complex tasks into reusable functions that can be sourced and executed within other scripts in the project.

Contents:
---------

1. azure_commands.sh
   - This script includes functions for logging in with a Service Principal, granting access to Key Vault secrets, creating or displaying resource group information, and managing Key Vault creation. It also contains a function to reset the client secret of a service principal and store it in Azure Key Vault.

2. dialog-utilities.sh
   - Contains functions for presenting interactive prompts and dialogs to the user, allowing them to make choices about their environment configuration, Kubernetes deployment options, and Terraform plan application.

3. error-handler.sh
   - Provides error handling utilities for processing standard error streams from Terraform commands. It includes functions to handle "resource already exists" errors by attempting to import the resource into Terraform state.

4. file-utilities.sh
   - Offers functions to create and append content to configuration files for Terraform or Kubernetes. It also includes a retry mechanism for performing operations that may require multiple attempts due to transient issues.

5. terraform-commands.sh
   - This script is dedicated to Terraform-specific operations such as generating timestamps, creating new plan filenames, checking connectivity, and managing Terraform workspaces.

Usage:
------

To utilize these library scripts, source the desired script at the beginning of your shell script using the `source` command. For example:

source "/path/to/libraries/azure_commands.sh"

Once sourced, you can call any function defined within the script as if it were a part of your own script.


Note:
----

These scripts are intended for use by developers and operations teams who have a working knowledge of Azure, Terraform, and shell scripting. They should be used with an understanding of the actions they perform, especially when modifying cloud resources or sensitive configurations.
Always review the functions and their associated comments before using them to ensure they meet the needs of your specific task or workflow.