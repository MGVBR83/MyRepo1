resource "azurerm_key_vault" "kv" {
  name                        = var.kv_name
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = var.disk_encryption_enabled
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  sku_name                    = var.kv_sku
  tags                        = var.tags
  dynamic "network_acls " {
    for_each = var.network_acls
    content {
      bypass                     = each.network_acls.bypass
      default_action             = each.network_acls.default_action
      ip_rules                   = each.network_acls.ip_rules
      virtual_network_subnet_ids = each.network_acls.virtual_network_subnet_ids
    }
  }
}
