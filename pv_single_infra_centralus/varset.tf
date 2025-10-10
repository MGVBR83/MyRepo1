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
autoscale_capacity = {
  minimum = "2"
  maximum = "10"
  default = "2"
}
autoscale_rules = {
  scale_out = {
    metric_name        = "MemoryPercentage"
    metric_namespace   = "Microsoft.Web/serverfarms"
    time_grain         = "PT1M"
    statistic          = "Average"
    time_window        = "PT5M"
    time_aggregation   = "Average"
    operator           = "GreaterThan"
    threshold          = 50
    direction          = "Increase"
    scale_type         = "ChangeCount"
    scale_value        = "1"
    cooldown           = "PT5M"
  },
  scale_in = {
    metric_name        = "MemoryPercentage"
    metric_namespace   = "Microsoft.Web/serverfarms"
    time_grain         = "PT1M"
    statistic          = "Average"
    time_window        = "PT5M"
    time_aggregation   = "Average"
    operator           = "LessThan"
    threshold          = 25
    direction          = "Decrease"
    scale_type         = "ChangeCount"
    scale_value        = "1"
    cooldown           = "PT5M"
  }
}


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
  minimum_tls_version                      = "1.2"
  worker_count                    = 2
  container_registry_use_managed_identity = true
  container_registry_managed_identity_client_id  = "11111111-2222-3333-4444-555555555555"
  websockets_enabled                   = true
  ftps_state                           = "Disabled"
}

#App Service Slot Values
app_svc_slot_name = "beta"
app_svc_slot_site_config = {
  always_on         = true
  http2_enabled     = true
  worker_count = 1
  websockets_enabled = true
  scm_type           = "LocalGit"
}


