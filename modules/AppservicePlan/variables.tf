variable "rg_name" {
  type = string
}
variable "appsvc_plan_name" {
  type = string
}
variable "appsvc_plan_kind" {
  type    = string
  default = "Windows"
}
variable "appsvc_plan_sku" {
  type    = string
  default = "Standard"
}
variable "appsvc_plan_size" {
  type    = string
  default = "S1"
}
variable "appsvc_plan_capacity" {
  type    = string
  default = "2"
}
