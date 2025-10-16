variable "nsg_name" {
  description = "Name which should be used for this Resource Group"
  type        = string
}

variable "location" {
  description = "Name which should be used for this Resource Group"
  type        = string
}

variable "security_rule_list" {
  description = "List of security_rule objects representing security rules"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "mapping of tags which should be assigned to the Resource Group."
  type        = map(any)
  default     = {}
}

variable "rg_name" {
  description = "Name which should be used for this Resource Group"
  type        = string
}

variable "subnet_id_list" {
  description = "Subnets to which NSG is to be assocuated"
  type        = list(any)
  default     = []
}
