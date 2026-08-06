output "id" {
  description = "Resource ID of the image template."
  value       = azapi_resource.this.id
}

output "name" {
  description = "Name of the image template."
  value       = azapi_resource.this.name
}

output "output" {
  description = "Full ARM response body of the image template resource."
  value       = azapi_resource.this.output
}
