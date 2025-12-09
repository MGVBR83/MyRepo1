variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "storage_account_name" {
  description = "Unique Storage Account name"
  type        = string
}

variable "account_tier" {
  description = "Storage Account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "storage_containers" {
  description = "Map of storage containers to create"
  type = map(object({
    access_type = string # private, blob, container
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
