data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "westeurope"
}

resource "azurerm_key_vault" "example" {
  name                = "examplekv"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                 = "standard"
  purge_protection_enabled = true
}

resource "azurerm_key_vault_access_policy" "test" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Get",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}

resource "azurerm_storage_account" "example" {
  name                     = "examplesa"
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_ai_services" "example" {
  name                = "exampleaiservices"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "S0"
}

resource "azurerm_ai_foundry" "example" {
  name                = "exampleaihub"
  location            = azurerm_ai_services.example.location
  resource_group_name = azurerm_resource_group.example.name
  storage_account_id  = azurerm_storage_account.example.id
  key_vault_id        = azurerm_key_vault.example.id

  identity {
    type = "SystemAssigned"
  }
}
