resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  tags = var.tags
}

# Create multiple containers dynamically (optional)
resource "azurerm_storage_container" "containers" {
  for_each              = var.storage_containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = each.value.access_type
}
