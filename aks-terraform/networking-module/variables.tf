variable "resource_group_name" {
  description = "Represents the Resource Group where networking resources will be deployed."
  type        = string
  default     = "networking-rg"
}

variable "location" {
  description = "Specifies the Azure region where networking resources will be deployed."
  type        = string
  default     = "UK South"
}

variable "vnet_address_space" {
  description = "Defines the address space for the Virtual Network in the main configuration."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}
