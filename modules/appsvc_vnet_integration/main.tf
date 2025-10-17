resource "azurerm_app_service_virtual_network_swift_connection" "appsvc_vnet" {
  app_service_id = var.app_service_id
  subnet_id      = var.subnet_id
}

resource "azurerm_app_service_slot_virtual_network_swift_connection" "appsvc_slot_vnet" {
  slot_name      = var.app_service_slot_name
  app_service_id = var.app_service_id
  subnet_id      = var.subnet_id
}