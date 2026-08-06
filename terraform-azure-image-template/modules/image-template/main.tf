# This mirrors the AzAPI Terraform resource example for
# Microsoft.VirtualMachineImages/imageTemplates directly - body.properties
# is set straight from var.properties with no intermediate locals/reshaping.

resource "azapi_resource" "this" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2025-10-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location

  identity {
    type         = var.identity.type
    identity_ids = var.identity.identity_ids
  }

  tags = var.tags

  body = {
    properties = var.properties
  }

  response_export_values    = ["*"]
  schema_validation_enabled = true
}
