variable "prefix" {
  description = "Prefix of the Application name"
  type        = string
  default     = "tfvmex"
}

variable "location" {
  description = "Location of environment"
  type        = string
  default     = "West Europe"
}

variable "vnet_address_space" {
  description = "Adress space of the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "nicname" {
  description = "Name of the Network Interface Card"
  type        = string
  default     = "testconfiguration1"
}

variable "vmsize" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_DS1_v2"
}
