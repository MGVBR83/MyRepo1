variable "rg_name" {
	description = "Name which should be used for this Resource Group"
	type = string
}

variable "kv_name" {
	description = "the name of the Key Vault. Changing this forces a new resource to be created. The name must be globally unique. If the vault is in a recoverable state then the vault will need to be purged before reusing the name."
	type = string
}

variable "disk_encryption_enabled" {
	description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
	type = bool
}

variable "soft_delete_retention_days" {
	description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
	type = number
}

variable "purge_protection_enabled" {
	description = " Is Purge Protection enabled for this Key Vault?"
	type = bool
}

variable "kv_sku" {
	description = " The Name of the SKU used for this Key Vault. Possible values are standard and premium`cb"
	type = string
}

variable "network_acls" {
	description = "map of network ACLs"
	type = map(object)
}

variable "kv_access_policy" {
	description = "List of KV access Policies"
	type = map(object)
}
variable "tags" {
	description = "mapping of tags which should be assigned to the Resource Group."
	type = map(any)
	default = {}
}