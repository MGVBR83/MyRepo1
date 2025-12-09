output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

output "storage_container_names" {
  value = [for c in azurerm_storage_container.containers : c.name]
}
