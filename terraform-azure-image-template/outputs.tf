output "image_template_ids" {
  description = "Map of image template name => resource ID."
  value       = { for k, m in module.image_template : k => m.id }
}

output "image_template_outputs" {
  description = "Map of image template name => full ARM response body (properties, provisioningState, lastRunStatus, etc.)."
  value       = { for k, m in module.image_template : k => m.output }
}
