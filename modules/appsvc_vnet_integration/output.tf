output "appsvc_vnet_integration_id" {
  value = azurerm_app_service_virtual_network_swift_connection.appsvc_vnet.id
}

output "appsvc_slot_vnet_integration_id" {
  value = azurerm_app_service_slot_virtual_network_swift_connection.appsvc_slot_vnet.id
}