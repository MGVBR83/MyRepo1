module "private_link_service" {
  source = "../modules/private_link_service"   # update the path based on your folder structure

  pvt_link_name = "my-private-link-svc"
  rg_name       = azurerm_resource_group.rg.name
  location      = azurerm_resource_group.rg.location

  approval_subscription_ids  = [
    "11111111-2222-3333-4444-555555555555",
    "66666666-7777-8888-9999-000000000000"
  ]

  visibility_subscription_ids = [
    "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  ]

  lb_fe_ip_ids = [
    azurerm_lb.lb.frontend_ip_configuration[0].id
  ]

  nat_ip_configs = [
    {
      name               = "primary"
      private_ip_address = "10.5.1.17"
      subnet_id          = azurerm_subnet.example.id
      primary            = true
    },
    # Add more NAT configs if needed
    # {
    #   name               = "secondary"
    #   private_ip_address = "10.5.1.18"
    #   subnet_id          = azurerm_subnet.example.id
    #   primary            = false
    # }
  ]
}
