variable "name" {
  description = "Name of the image template. Must match ^[A-Za-z0-9-_.]{1,64}$."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-_.]{1,64}$", var.name))
    error_message = "name must match ^[A-Za-z0-9-_.]{1,64}$ (max 64 chars)."
  }
}

variable "resource_group_id" {
  description = "Resource ID of the resource group to deploy the image template into (used as parent_id)."
  type        = string
}

variable "location" {
  description = "Azure region for the image template."
  type        = string
}

variable "identity" {
  description = "Managed identity for the image template: { type = \"UserAssigned\"|\"None\", identity_ids = [...] }"
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })

  validation {
    condition     = contains(["None", "UserAssigned"], var.identity.type)
    error_message = "identity.type must be \"None\" or \"UserAssigned\"."
  }
}

variable "tags" {
  description = "Tags to apply to the image template resource itself."
  type        = map(string)
  default     = null
}

variable "properties" {
  description = <<-EOT
    The full ImageTemplateProperties object, passed straight through to the
    azapi_resource body exactly as defined by the ARM schema (camelCase keys) -
    e.g. source, distribute, customize, buildTimeoutInMinutes, autoRun,
    errorHandling, managedResourceTags, optimize, stagingResourceGroup,
    validate, vmProfile, additionalDataDisks.

    No reshaping happens in this module: whatever object you pass here is
    exactly what lands under body.properties. source/customize/distribute/
    validate.inVMValidations are ARM discriminated unions keyed on "type" -
    see the root README for a per-type shape reference.
  EOT
  type = any

  validation {
    condition     = try(var.properties.source, null) != null
    error_message = "properties.source is required."
  }

  validation {
    condition     = try(length(var.properties.distribute), 0) > 0
    error_message = "properties.distribute must contain at least one distributor object."
  }
}
