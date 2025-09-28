output "id" {
    value = azurerm_key_vault.kv.id
}

output "vault_uri" {
    value = azurerm_key_vault.kv.vault_uri
}

output "kv_access_policy_id" {
    value = azurerm_key_vault_access_policy.kv_access_policy.id
}

