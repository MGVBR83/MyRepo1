variable "rg_name" {
  type = string
}
variable "appsvc_plan_name" {
  type = string
}
variable "appsvc_plan_kind" {
  type    = string
  default = "Linux"
}
variable "appsvc_plan_sku" {
  type    = string
  default = "Standard"
}
variable "appsvc_plan_size" {
  type    = string
  default = "S1"
}
variable "asp_reserved" {
  type    = bool
  default = true
}
variable "tags" {
  type = map(any)
}
variable "autoscale_capacity" {
  description = "Autoscale capacity configuration"
  type = object({
    minimum = string
    maximum = string
    default = string
  })
}
variable "autoscale_rules" {
  description = "List of autoscale rules with metric and scale action parameters"
  type = map(any)
}
