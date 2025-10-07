# RG Vars values
rg_name  = "rg-np-pc-pvs-centralus"
location = "central us"
tags = {
  AIDE_ID     = "123456"
  app_name    = "PV Single"
  Environment = "Dev"
}

#Keyvault Values
kv_name = "kvnppvscentralus"
kv_sku  = "standard"
network_acls = [
  {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = ["52.168.12.34"]
    virtual_network_subnet_ids = ["/subscriptions/<subid>/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/app-subnet"]
  }
]

kv_access_policy = {
  spn1 = {
    object_id               = "00000000-0000-0000-0000-000000000000"
    key_permissions         = ["Get", "List"]
    secret_permissions      = ["Get", "List", "Set"]
    certificate_permissions = ["Get", "List"]
    storage_permissions     = []
  }
  user1 = {
    object_id               = "11111111-1111-1111-1111-111111111111"
    key_permissions         = ["Get"]
    secret_permissions      = ["Get"]
    certificate_permissions = []
    storage_permissions     = []
  }
}

# App Service Plan values
appsvc_plan_name = "asp-dev-pvs-centralus"
appsvc_plan_kind = "Linux"
appsvc_plan_sku   = "PremiumV2"
appsvc_plan_size  = "P0v3"
appsvc_plan_capacity = 2

#App Service Values
appsvc_name               = "as-dev-pvs-centralus"
app_settings = {
  WEBSITE_RUN_FROM_PACKAGE        = "1"
  APPINSIGHTS_INSTRUMENTATIONKEY  = "0000-1111-2222-3333"
}
app_svc_identity = {
  type         = "SystemAssigned, UserAssigned"
  identity_ids = ["/subscriptions/xxxx/resourceGroups/rg-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demo-uai"]
}
app_svc_site_config = {
  always_on                            = true
  http2_enabled                        = true
  min_tls_version                      = "1.2"
  number_of_workers                    = 2
  acr_use_managed_identity_credentials = true
  acr_user_managed_identity_client_id  = "11111111-2222-3333-4444-555555555555"
  websockets_enabled                   = true
  ftps_state                           = "Disabled"
}

#App Service Slot Values
app_svc_slot_name = "beta"
app_svc_slot_site_config = {
  always_on         = true
  http2_enabled     = true
  number_of_workers = 1
  websockets_enabled = true
  scm_type           = "LocalGit"
}


