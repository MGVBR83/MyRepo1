# RG Vars values
rg_name  = "rg-np-pc-pvs-centralus"
location = "central us"
tags = {
  AIDE_ID     = "123456"
  app_name    = "PV Single"
  Environment = "Dev"
}

# Vnet values
vnet_name = "vnet-np-pc-pvs-centralus"
vnet_cidr = ["10.248.184.0/22"]
subnet_list = {
  dev = {
    subnet_name = "snet-dev-pc-pvs-centralus"
    subnet_cidr = ["10.248.184.0/25"]
    service_endpoints = ["Microsoft.KeyVault", "Microsoft.Web"]
    delegation = {
      name = "delegation-devappservice"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
  stage = {
    subnet_name = "snet-stg-pc-pvs-centralus"
    subnet_cidr = ["10.248.184.128/25"]
  }
  uat = {
    subnet_name = "snet-uat-pc-pvs-centralus"
    subnet_cidr = ["10.248.185.0/25"]
  }
}

#NSG values
nsg_name = "nsg-np-pc-pvs-centralus"
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
  }
]

dev_subnet_id = "/subscriptions/<subid>/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/app-subnet"

stage_subnet_id = "/subscriptions/<subid>/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/app-subnet"

uat_subnet_id = "/subscriptions/<subid>/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/app-subnet"

subnet_id_list = [ 
  "",
  "",
  "" 
]
