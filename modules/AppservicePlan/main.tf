resource "azurerm_app_service_plan" "appservice" {
  name                = var.appsvc_plan_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = var.appsvc_plan_kind

  sku {
    tier     = var.appsvc_plan_sku
    size     = var.appsvc_plan_size
    capacity = var.appsvc_plan_capacity
  }
}
