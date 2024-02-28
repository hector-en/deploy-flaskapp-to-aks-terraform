# This file was created by 05-setup-root-configuration.sh for the root module.

# Input variable for the Client ID of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_id" {
  description = "The Client ID of the Azure Service Principal"
  type        = string
}

# Input variable for the Client Secret of the Azure Service Principal.
# This value will be used when authenticating to Azure.
variable "client_secret" {
  description = "The Client Secret of the Azure Service Principal"
  type        = string
  sensitive   = true
}

# Input variable for the Tenant ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "tenant_id" {
  description = "The Tenant ID of the Azure account"
  type        = string
}

# Input variable for the Subscription ID of the Azure account.
# This value will be used when authenticating to Azure.
variable "subscription_id" {
  description = "The Subscription ID of the Azure account"
  type        = string
}
