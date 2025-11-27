resource "azurerm_private_link_service" "pvtlink" {
  name                = var.pvt_link_name
  resource_group_name = var.rg_name
  location            = var.location
  auto_approval_subscription_ids              = try(var.approval_subscription_ids, [])
  visibility_subscription_ids                 = try(var.visibility_subscription_ids, [])
  load_balancer_frontend_ip_configuration_ids = try(var.lb_fe_ip_ids, [])

  dynamic "nat_ip_configuration" {
    for_each = var.nat_ip_configs
    content {
      name                       = nat_ip_configuration.value.name
      private_ip_address         = nat_ip_configuration.value.private_ip_address
      private_ip_address_version = "IPv4"
      subnet_id                  = nat_ip_configuration.value.subnet_id
      primary                    = try(nat_ip_configuration.value.primary, true)
    }
  }
}