variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "TeamRaders"
}

variable "location" {
  description = "The Azure region for the resources"
  type        = string
  default     = "centralindia"
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "dev-buddiedeals-vnet"
}

variable "vnet_cidr" {
  description = "The CIDR range for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "The list of public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnets" {
  description = "The list of private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
  default     = "devbuddiedealsstorage"
}

variable "container_name" {
  description = "The name of the blob container"
  type        = string
  default     = "terraform-state"
}

variable "log_analytics_workspace_name" {
  description = "The name of the log analytics workspace"
  type        = string
  default     = "dev-buddiedeals-log"
}

variable "ARM_SUBSCRIPTION_ID" {}
variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_TENANT_ID" {}
