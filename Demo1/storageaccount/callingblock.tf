module "rg_sa" {
  source = "./modules/storage_rg_module"

  resource_group_name  = "demo-rg"
  location             = "East US"
  storage_account_name = "demostorageacct123"

  storage_containers = {
    appdata = { access_type = "private" }
    logs    = { access_type = "blob" }
  }

  tags = {
    environment = "dev"
    owner       = "vinay"
  }
}
