resource "azurerm_linux_web_app" "appsvc" {
  name                = var.appsvc_name
  location            = var.app_service_plan_location
  resource_group_name = var.app_service_plan_rg_name
  service_plan_id     = var.app_service_plan_id
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
      always_on                                     = lookup(site_config.value, "always_on", true)
      ftps_state                                    = lookup(site_config.value, "ftps_state", "AllAllowed")
      http2_enabled                                 = lookup(site_config.value, "http2_enabled", false)
      scm_use_main_ip_restriction                   = lookup(site_config.value, "scm_use_main_ip_restriction", false)
      minimum_tls_version                           = lookup(site_config.value, "minimum_tls_version", "1.2")
      remote_debugging_enabled                      = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version                      = lookup(site_config.value, "remote_debugging_version", "VS2022")
      use_32_bit_worker                             = lookup(site_config.value, "use_32_bit_worker", true)
      vnet_route_all_enabled                        = lookup(site_config.value, "vnet_route_all_enabled", false)
      websockets_enabled                            = lookup(site_config.value, "websockets_enabled", true)
      worker_count                                  = lookup(site_config.value, "worker_count", 1)
      container_registry_managed_identity_client_id = lookup(site_config.value, "container_registry_managed_identity_client_id", false)
      container_registry_use_managed_identity       = lookup(site_config.value, "container_registry_use_managed_identity", null)

      dynamic "application_stack" {
        for_each = lookup(site_config.value, "application_stack", null) != null ? [site_config.value.application_stack] : []
        content {
          dotnet_version           = lookup(application_stack.value, "dotnet_version", null)
          java_version             = lookup(application_stack.value, "java_version", null)
          python_version           = lookup(application_stack.value, "python_version", null)
          node_version             = lookup(application_stack.value, "node_version", null)
          php_version              = lookup(application_stack.value, "php_version", null)
          ruby_version             = lookup(application_stack.value, "ruby_version", null)
          go_version               = lookup(application_stack.value, "go_version", null)
          docker_image_name        = lookup(application_stack.value, "docker_image_name", null)
          docker_registry_url      = lookup(application_stack.value, "docker_registry_url", null)
          docker_registry_username = lookup(application_stack.value, "docker_registry_username", null)
          docker_registry_password = lookup(application_stack.value, "docker_registry_password", null)
        }
      }
    }
  }
}


resource "azurerm_linux_web_app_slot" "appsvc_slot" {
  name            = var.app_svc_slot_name
  app_service_id  = azurerm_linux_web_app.appsvc.id
  service_plan_id = var.app_service_plan_id

  dynamic "site_config" {
    for_each = var.app_svc_slot_site_config != null ? [var.app_svc_slot_site_config] : []
    content {
      always_on                                     = lookup(site_config.value, "always_on", true)
      ftps_state                                    = lookup(site_config.value, "ftps_state", "AllAllowed")
      http2_enabled                                 = lookup(site_config.value, "http2_enabled", false)
      scm_use_main_ip_restriction                   = lookup(site_config.value, "scm_use_main_ip_restriction", false)
      minimum_tls_version                           = lookup(site_config.value, "minimum_tls_version", "1.2")
      remote_debugging_enabled                      = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version                      = lookup(site_config.value, "remote_debugging_version", "VS2022")
      use_32_bit_worker                             = lookup(site_config.value, "use_32_bit_worker", true)
      vnet_route_all_enabled                        = lookup(site_config.value, "vnet_route_all_enabled", false)
      websockets_enabled                            = lookup(site_config.value, "websockets_enabled", true)
      worker_count                                  = lookup(site_config.value, "worker_count", 1)
      container_registry_managed_identity_client_id = lookup(site_config.value, "container_registry_managed_identity_client_id", false)
      container_registry_use_managed_identity       = lookup(site_config.value, "container_registry_use_managed_identity", null)
      app_command_line                              = lookup(site_config.value, "app_command_line", null)

      dynamic "application_stack" {
        for_each = lookup(site_config.value, "application_stack", null) != null ? [site_config.value.application_stack] : []
        content {
          dotnet_version           = lookup(application_stack.value, "dotnet_version", null)
          java_version             = lookup(application_stack.value, "java_version", null)
          python_version           = lookup(application_stack.value, "python_version", null)
          node_version             = lookup(application_stack.value, "node_version", null)
          php_version              = lookup(application_stack.value, "php_version", null)
          ruby_version             = lookup(application_stack.value, "ruby_version", null)
          go_version               = lookup(application_stack.value, "go_version", null)
          docker_image_name        = lookup(application_stack.value, "docker_image_name", null)
          docker_registry_url      = lookup(application_stack.value, "docker_registry_url", null)
          docker_registry_username = lookup(application_stack.value, "docker_registry_username", null)
          docker_registry_password = lookup(application_stack.value, "docker_registry_password", null)
        }
      }
    }
  }
}
