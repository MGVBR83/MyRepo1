# Reads the YAML input file and creates one image template per entry under
# `image_templates`. Each entry's `properties` block is passed straight
# through to the child module, which passes it straight through to the
# azapi_resource body - no reshaping happens anywhere in this chain.

locals {
  # Parsing the input file, not building the resource body.
  image_templates = yamldecode(file(var.image_templates_file)).image_templates
}

module "image_template" {
  source = "./modules/image-template"

  for_each = { for img in local.image_templates : img.name => img }

  name               = each.value.name
  resource_group_id  = each.value.resource_group_id
  location           = each.value.location
  identity           = each.value.identity
  tags               = try(each.value.tags, null)
  properties         = each.value.properties
}

# Fails the plan if two entries in the YAML file share the same `name`,
# since that would otherwise silently collapse to one map key above.
check "unique_image_template_names" {
  assert {
    condition = length(local.image_templates) == length(distinct([
      for img in local.image_templates : img.name
    ]))
    error_message = "image_templates_file contains duplicate 'name' values; names must be unique."
  }
}
