resource "azurerm_resource_group" "rg" {
  # This resource block creates the resource group for AKS cluster resources in Azure.
  name     = var.resource_group_name
  location = var.location
}
