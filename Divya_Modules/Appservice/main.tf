resource "azurerm_app_service" "appsvc" {
  name                = var.appsvc_name
  location            = var.app_service_plan_location
  resource_group_name = var.app_service_plan_rg_name
  app_service_plan_id = var.app_service_plan_id
  app_settings        = var.app_settings

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = lookup(identity.value, "type", "SystemAssigned")
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  dynamic "site_config" {
    for_each = var.app_svc_site_config != null ? [var.app_svc_site_config] : []
    content {
      acr_use_managed_identity_credentials = lookup(site_config.value, "acr_use_managed_identity_credentials", false)
      acr_user_managed_identity_client_id  = lookup(site_config.value, "acr_user_managed_identity_client_id", null)
      always_on                            = lookup(site_config.value, "always_on", true)
      dotnet_framework_version             = lookup(site_config.value, "dotnet_framework_version", "v4.0")
      ftps_state                           = lookup(site_config.value, "ftps_state", "AllAllowed")
      number_of_workers                    = lookup(site_config.value, "number_of_workers", 1)
      http2_enabled                        = lookup(site_config.value, "http2_enabled", false)
      ip_restriction                       = lookup(site_config.value, "ip_restriction", [])
      scm_use_main_ip_restriction          = lookup(site_config.value, "scm_use_main_ip_restriction", false)
      scm_ip_restriction                   = lookup(site_config.value, "scm_ip_restriction", [])
      java_version                         = lookup(site_config.value, "java_version", null)
      java_container                       = lookup(site_config.value, "java_container", null)
      java_container_version               = lookup(site_config.value, "java_container_version", null)
      local_mysql_enabled                  = lookup(site_config.value, "local_mysql_enabled", false)
      managed_pipeline_mode                = lookup(site_config.value, "managed_pipeline_mode", "Integrated")
      min_tls_version                      = lookup(site_config.value, "min_tls_version", "1.2")
      php_version                          = lookup(site_config.value, "php_version", null)
      python_version                       = lookup(site_config.value, "python_version", null)
      remote_debugging_enabled             = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version             = lookup(site_config.value, "remote_debugging_version", "VS2022")
      scm_type                             = lookup(site_config.value, "scm_type", "None")
      use_32_bit_worker_process            = lookup(site_config.value, "use_32_bit_worker_process", true)
      vnet_route_all_enabled               = lookup(site_config.value, "vnet_route_all_enabled", false)
      websockets_enabled                   = lookup(site_config.value, "websockets_enabled", true)
    }
  }
}

resource "azurerm_app_service_slot" "appsvc_slot" {
  name                = var.app_svc_slot_name
  app_service_name    = azurerm_app_service.appsvc.name
  location            = var.app_service_plan_location
  resource_group_name = var.app_service_plan_rg_name
  app_service_plan_id = var.app_service_plan_id

  dynamic "site_config" {
    for_each = var.app_svc_slot_site_config != null ? [var.app_svc_slot_site_config] : []
    content {
      acr_use_managed_identity_credentials = lookup(site_config.value, "acr_use_managed_identity_credentials", false)
      acr_user_managed_identity_client_id  = lookup(site_config.value, "acr_user_managed_identity_client_id", null)
      always_on                            = lookup(site_config.value, "always_on", true)
      dotnet_framework_version             = lookup(site_config.value, "dotnet_framework_version", "v4.0")
      ftps_state                           = lookup(site_config.value, "ftps_state", "AllAllowed")
      number_of_workers                    = lookup(site_config.value, "number_of_workers", 1)
      http2_enabled                        = lookup(site_config.value, "http2_enabled", false)
      ip_restriction                       = lookup(site_config.value, "ip_restriction", [])
      scm_use_main_ip_restriction          = lookup(site_config.value, "scm_use_main_ip_restriction", false)
      scm_ip_restriction                   = lookup(site_config.value, "scm_ip_restriction", [])
      java_version                         = lookup(site_config.value, "java_version", null)
      java_container                       = lookup(site_config.value, "java_container", null)
      java_container_version               = lookup(site_config.value, "java_container_version", null)
      local_mysql_enabled                  = lookup(site_config.value, "local_mysql_enabled", false)
      managed_pipeline_mode                = lookup(site_config.value, "managed_pipeline_mode", "Integrated")
      min_tls_version                      = lookup(site_config.value, "min_tls_version", "1.2")
      php_version                          = lookup(site_config.value, "php_version", null)
      python_version                       = lookup(site_config.value, "python_version", null)
      remote_debugging_enabled             = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version             = lookup(site_config.value, "remote_debugging_version", "VS2022")
      scm_type                             = lookup(site_config.value, "scm_type", "None")
      use_32_bit_worker_process            = lookup(site_config.value, "use_32_bit_worker_process", true)
      vnet_route_all_enabled               = lookup(site_config.value, "vnet_route_all_enabled", false)
      websockets_enabled                   = lookup(site_config.value, "websockets_enabled", true)
    }
  }
}
