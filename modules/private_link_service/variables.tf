variable "pvt_link_name" {
  description = "Name of the Private Link Service"
  type        = string
}

variable "rg_name" {
  description = "Resource group name where the Private Link Service will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "approval_subscription_ids" {
  description = "List of subscription IDs for auto approval"
  type        = list(string)
  default     = []
}

variable "visibility_subscription_ids" {
  description = "List of subscription IDs that can see the Private Link Service"
  type        = list(string)
  default     = []
}

variable "lb_fe_ip_ids" {
  description = "List of Load Balancer Frontend IP Configuration IDs"
  type        = list(string)
  default     = []
}

variable "nat_ip_configs" {
  description = "List of NAT IP configuration objects for the Private Link Service"
  type = list(object({
    name               = string
    private_ip_address = string
    subnet_id          = string
    primary            = optional(bool, false)
  }))
}
