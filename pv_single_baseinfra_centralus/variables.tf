variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(any)
}

variable "vnet_name" {
  type = string
}

variable "vnet_cidr" {
  type = list(string)
}

variable "subnet_list" {
    type = map(any)
}

variable "nsg_name" {
  type = string
}

variable "security_rule_list" {
  type = list
}

variable "subnet_id_list" {
  type = list
}

# variable "dev_subnet_id" {
#   type = string
# }

# variable "stage_subnet_id" {
#   type = string
# }

# variable "uat_subnet_id" {
#   type = string
# }