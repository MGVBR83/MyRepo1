variable "appsvc_name" {
    type = string
}

variable "app_service_plan_location" {
    type = string
}

variable "app_service_plan_rg_name" {
    type = string
}

variable "app_service_plan_id" {
    type = string
}

variable "identity" {
  description = "Managed identity configuration for the App Service"
  type = object({
    type         = string       # "SystemAssigned", "UserAssigned", or "SystemAssigned, UserAssigned"
    identity_ids = optional(list(string))
  })
  default = null
}

variable "app_settings" {
    type = map(any)
    default = {}
}

variable "app_svc_site_config" {
    type = string
}

variable "app_svc_slot_name" {
    type = string
}

variable "app_svc_slot_site_config" {
    type = string
}