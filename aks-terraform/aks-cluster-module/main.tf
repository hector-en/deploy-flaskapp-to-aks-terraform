resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
# This resource block creates a resource group in Azure.
  location = var.location
}
