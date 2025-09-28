resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  for_each     = var.kv_access_policy
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.object_id

  key_permissions = try(each.key_permissions, [])
  secret_permissions = try(each.secret_permissions, [])
  certificate_permissions = try(each.certificate_permissions, [])
  storage_permissions = try(each.storage_permissions, [])
}
