resource "azurerm_app_service_plan" "appservice" {
  name                = var.appsvc_plan_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = var.appsvc_plan_kind
  reserved            = var.asp_reserved
  zone_redundant      = true

  sku {
    tier     = var.appsvc_plan_sku
    size     = var.appsvc_plan_size
  }
  tags = var.tags
}

############################################################
# 3️⃣ Rules-Based Autoscale (Memory threshold = 4 GB)
############################################################
resource "azurerm_monitor_autoscale_setting" "asp_autoscale" {
  name                = format("%s-autoscale", var.appsvc_plan_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  target_resource_id  = azurerm_app_service_plan.appsvc_plan.id
  enabled             = true

  profile {
    name = format("%s-DynamicScalingProfile", var.appsvc_plan_name)

    capacity {
      minimum = var.autoscale_capacity.minimum
      maximum = var.autoscale_capacity.maximum
      default = var.autoscale_capacity.default
    }

    dynamic "rule" {
      for_each = var.autoscale_rules
      content {
        metric_trigger {
          metric_name        = rule.value.metric_name
          metric_namespace   = try(rule.value.metric_namespace, null)
          metric_resource_id = azurerm_app_service_plan.appsvc_plan.id
          time_grain         = rule.value.time_grain
          statistic          = rule.value.statistic
          time_window        = rule.value.time_window
          time_aggregation   = rule.value.time_aggregation
          operator           = rule.value.operator
          threshold          = rule.value.threshold
        }

        scale_action {
          direction = rule.value.direction
          type      = rule.value.scale_type
          value     = rule.value.scale_value
          cooldown  = rule.value.cooldown
        }
      }
    }
  }

  tags = var.tags
}

