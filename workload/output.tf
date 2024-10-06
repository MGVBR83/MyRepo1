output "rg_name" {
  description = "Name of the resource group"
  value = azurerm_resource_group.myrg.name
}

output "rg_id" {
  description = "Id of the resource group"
  value = azurerm_resource_group.myrg.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value = azurerm_virtual_network.myvnet.name
}

output "vm_name" {
  description = "Name of the Virtual Machine"
  value = azurerm_virtual_machine.myvm.name
}

output "vm_id" {
  description = "Id of the Virtual Machine"
  value = azurerm_virtual_machine.myvm.id
}
