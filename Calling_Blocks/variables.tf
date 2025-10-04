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

variable "subnet_id" {
  type = string
}

variable "kv_name" {
  type = string
}

variable "kv_sku" {
  type = string
}

variable "network_acls" {
  type = list
}

variable "kv_access_policy" {
  type = map(any)
}

variable "appsvc_plan_name" {
  type = string
}

variable "appsvc_plan_kind" {
  type    = string
}

variable "appsvc_plan_sku" {
  type    = string
}

variable "appsvc_plan_size" {
  type    = string
}

variable "appsvc_plan_capacity" {
  type    = string
}

variable "appsvc_name" {
  type        = string
  description = "Name of the App Service"
}

variable "app_settings" {
  type        = map(string)
  description = "App settings for the App Service"
  default     = {}
}

variable "app_svc_identity" {
  description = "App Service identity configuration"
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
}

variable "app_svc_site_config" {
  description = "Site configuration for the App Service"
  type        = map(any)
  default     = {}
}

variable "app_svc_slot_name" {
  type        = string
  description = "Name of the App Service deployment slot"
  default     = null
}

variable "app_svc_slot_site_config" {
  description = "Site configuration for the App Service slot"
  type        = map(any)
  default     = {}
}



