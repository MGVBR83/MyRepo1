module "key_vault" {
  source                     = "./modules/Keyvault"
  rg_name                    = var.rg_name
  kv_name                    = var.kv_name
  kv_sku                     = var.kv_sku
  disk_encryption_enabled    = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  tags                       = var.tags
  # Optional network ACLs
  network_acls = var.network_acls
  # Access Policies
  kv_access_policy = var.kv_access_policy
}

module "app_service_plan" {
  source               = "./modules/AppservicePlan"
  rg_name              = var.rg_name
  appsvc_plan_name     = var.appsvc_plan_name
  appsvc_plan_kind     = var.appsvc_plan_kind
  appsvc_plan_sku      = var.appsvc_plan_sku
  appsvc_plan_size     = var.appsvc_plan_size
  appsvc_plan_capacity = var.appsvc_plan_capacity
  tags                 = var.tags
}

module "app_service" {
  source                    = "./modules/Appservice"
  appsvc_name               = var.appsvc_name
  app_service_plan_id       = module.app_service_plan.id
  app_service_plan_rg_name  = var.rg_name
  app_service_plan_location = var.location
  app_settings              = var.app_settings
  identity                  = var.app_svc_identity
  app_svc_site_config       = var.app_svc_site_config
  app_svc_slot_name         = var.app_svc_slot_name
  app_svc_slot_site_config  = var.app_svc_slot_site_config
}










