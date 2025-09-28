variable "vnet_name" {
	description = "name of the virtual network."
	type = string
}

variable "vnet_cidr" {
	description = "address space that is used the virtual network. You can supply more than one address space."
	type = list(string)
    default = []
}

variable "tags" {
	description = "mapping of tags which should be assigned to the Resource Group."
	type = map(any)
	default = {}
}

variable "rg_name" {
	description = "Name which should be used for this Resource Group"
	type = string
}

variable "subnet_list" {
	description = "List of Subnets that needs to be created"
	type = list
    default = []
}
