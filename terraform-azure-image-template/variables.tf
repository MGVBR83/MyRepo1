variable "image_templates_file" {
  description = "Path to the YAML file defining one or more image templates. See images.yaml for the expected shape."
  type        = string
  default     = "${path.module}/images.yaml"
}
