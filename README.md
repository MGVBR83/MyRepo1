# Terraform Configuration Files

## Overview

This repository contains Terraform configuration files for creation of virtual machines in MyRepo1 repository.

## Usage

To use these Terraform configurations, follow these steps:

1. **Prerequisites**:
   - Ensure you have [Terraform installed](https://www.terraform.io/downloads.html).
   - [Optional] Install any cloud provider CLI tools (e.g., AWS CLI, Azure CLI).
   - Configure your cloud provider credentials.

2. **Clone the Repository**:
   git clone https://github.com/MGVBR83/MyRepo1.git

   cd MyRepo1
3. **Initialize Terraform**:
   terraform init

4. **Plan the Deployment**:
   terraform plan

5. **Apply the Configuration**:
   terraform apply

6. **Destroy the Infrastructure** (if needed):
   terraform destroy

# Terraform Configuration of MyRepo1 Repository

## Inputs

| Variable Name   | Description                            | Type      | Default Value | Required |
|------------------|----------------------------------------|-----------|---------------|----------|
| prefix               | Prefix of the Application name           | string          | "tfvmex"        | Yes        |
| location             | Location of environment                  | string          | "West Europe"   | Yes        |
| vnet_address_space   | Adress space of the Virtual Network      | string          | "10.0.0.0/16"   | Yes        |
| nicname              | Name of the Network Interface Card       | string          | "testconfiguration1" | Yes        |
| vmsize               | Size of the VM                           | string          | "Standard_DS1_v2" | Yes        |
## Outputs

| Output Name      | Description                            |
|------------------|----------------------------------------|
| rg_name              | Name of the resource group               |
| rg_id                | Id of the resource group                 |
| vnet_name            | Name of the Virtual Network              |
| vm_name              | Name of the Virtual Machine              |
| vm_id                | Id of the Virtual Machine                |
## Examples

### Example 1: Basic Configuration

To deploy a simple infrastructure, use the following example:

    module "example" {

        source = "./path/to/module"

        example_input = "value"
    }

### Example 2: Advanced Configuration

For a more complex setup, refer to this configuration:

    resource "aws_instance" "example" {

        ami           = "ami-12345678"

        instance_type = "t2.micro"

        tags = {

            Name = "ExampleInstance"

        }

    }

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Contact

For any inquiries, please reach out to mgvbravi83@gmail.com.
