variable "prefix" {
  default = "tfvmex"
}

variable "location" {
  type = string
  default = "West Europe"
}

variable "vnet_address_space" {
  type = string
  default = "10.0.0.0/16"
}

variable "nicname" {
  type = string
  default = "testconfiguration1"
}

variable "vmsize" {
  type = string
  default = "Standard_DS1_v2"
}