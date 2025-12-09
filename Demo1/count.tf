terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# create N resource groups using count
variable "rg_count" {
  type    = number
  default = 3
}

variable "location" {
  type    = string
  default = "East US"
}

variable "rg_prefix" {
  type    = string
  default = "demo-rg"
}

resource "azurerm_resource_group" "rg" {
  count    = var.rg_count
  name     = format("%s-%02d", var.rg_prefix, count.index + 1) # demo-rg-01, demo-rg-02 ...
  location = var.location
}

output "resource_group_names" {
  value = [for r in azurerm_resource_group.rg : r.name]
}
