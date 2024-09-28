output "rg_name" {
  value = azurerm_resource_group.myrg.name
}

output "rg_id" {
  value = azurerm_resource_group.myrg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.myvnet.name
}

output "vm_name" {
  value = azurerm_virtual_machine.myvm.name
}

output "vm_id" {
  value = azurerm_virtual_machine.myvm.id
}
