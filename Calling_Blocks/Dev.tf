# RG Vars values
rg_name  = "pv_dev"
location = "central us"
tags = {
  AIDE_ID     = "123456"
  app_name    = "PV_DEV"
  Environment = "Dev"
}

# Vnet values
vnet_name = "pv_vnet"
vnet_cidr = ["10.12.10.30/22"]
subnet_list = {
  app = {
    subnet_name = "app-subnet"
    subnet_cidr = ["10.20.1.0/24"]
  }
  db = {
    subnet_name = "db-subnet"
    subnet_cidr = ["10.20.2.0/24"]
    delegation = {
      name = "db-delegation"
      service_delegation = {
        name    = "Microsoft.Sql/managedInstances"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

#NSG values
nsg_name = "pv_nsg_name"
security_rule_list = [
  {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "Deny-All-Outbound"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
subnet_id = "/subscriptions/<subid>/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/app-subnet"

#Keyvault Values
kv_name = "pv_key_vault"
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
appsvc_plan_name = "my_app_svc_plan"
appsvc_plan_kind = "Windows"
appsvc_plan_sku   = "PremiumV2"
appsvc_plan_size  = "P1v2"
appsvc_plan_capacity = 2

#App Service Values
appsvc_name               = "demo-webapp"
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
app_svc_slot_name = "staging"
app_svc_slot_site_config = {
  always_on         = true
  http2_enabled     = true
  number_of_workers = 1
  websockets_enabled = true
  scm_type           = "LocalGit"
}


