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

# create a resource group for the demo (single)
resource "azurerm_resource_group" "rg" {
  name     = "demo-nsg-rg"
  location = var.location
}

# the NSGs to create: map key = nsg name, value = object with security_rules (map)
variable "nsgs" {
  description = "Map of NSGs to create. Each value must be an object containing a map `security_rules`."
  type = map(object({
    security_rules = map(object({
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = string
      destination_port_range       = string
      source_address_prefix        = string
      destination_address_prefix   = string
    }))
  }))
  default = {
    "web-nsg" = {
      security_rules = {
        "allow_http" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        "allow_https" = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }

    "management-nsg" = {
      security_rules = {
        "allow_ssh" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "10.0.0.0/24"
          destination_address_prefix = "*"
        }
      }
    }
  }
}

variable "location" {
  type    = string
  default = "East US"
}

# create one NSG per map entry (stable key is the map key)
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.nsgs
  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # dynamic block to expand the security_rules map into multiple security_rule blocks
  dynamic "security_rule" {
    for_each = each.value.security_rules
    iterator = sr
    content {
      name                       = sr.key
      priority                   = sr.value.priority
      direction                  = sr.value.direction
      access                     = sr.value.access
      protocol                   = sr.value.protocol
      source_port_range          = sr.value.source_port_range
      destination_port_range     = sr.value.destination_port_range
      source_address_prefix      = sr.value.source_address_prefix
      destination_address_prefix = sr.value.destination_address_prefix
    }
  }
}

output "created_nsgs" {
  value = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}
