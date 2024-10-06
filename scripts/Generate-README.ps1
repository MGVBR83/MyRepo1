param (
    [string]$GH_ORG_Name = "MGVBR83",     # Default value for GH_ORG_Name
    [int]$varNameWidth = 20,              # Default value for variable name width
    [int]$varDescWidth = 40,              # Default value for variable description width
    [int]$varTypeWidth = 15,              # Default value for variable type width
    [int]$defaultValueWidth = 15,         # Default value for default value width
    [int]$requiredWidth = 10               # Default value for required field width
)

# Request user inputs after parameter definitions
$desc_tf_action = Read-Host -Prompt "Please enter the description for the Terraform action"

$reponame = Read-Host -Prompt "Please enter the repository name for which README to be created"

# Define the output README file
$READMEFile = "README.md"


# Navigating to the working directory for tf configuration files
cd .\workload\

# Start the README content
@"
# Terraform Configuration Files

## Overview

This repository contains Terraform configuration files for $desc_tf_action.

## Usage

To use these Terraform configurations, follow these steps:

1. **Prerequisites**:
   - Ensure you have [Terraform installed](https://www.terraform.io/downloads.html).
   - [Optional] Install any cloud provider CLI tools (e.g., AWS CLI, Azure CLI).
   - Configure your cloud provider credentials.

2. **Clone the Repository**:
   git clone https://github.com/$GH_ORG_Name/$reponame.git

   cd $reponame
3. **Initialize Terraform**:
   terraform init

4. **Plan the Deployment**:
   terraform plan

5. **Apply the Configuration**:
   terraform apply

6. **Destroy the Infrastructure** (if needed):
   terraform destroy

# Terraform Configuration of $reponame Repository

## Inputs

| Variable Name   | Description                            | Type      | Default Value | Required |
|------------------|----------------------------------------|-----------|---------------|----------|
"@ | Out-File -Encoding utf8 -FilePath ..\$READMEFile

# Extract variables
Get-ChildItem -Filter "*.tf" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName

    foreach ($line in $content) {
        if ($line -match 'variable "(.*)"') {
            $varName = $matches[1].PadRight($varNameWidth)

            # Find description
            $descLine = $content[$content.IndexOf($line) + 1]
            if ($descLine -match 'description = "(.*)"') {
                $varDesc = $matches[1].PadRight($varDescWidth)
            }

            # Find type
            $typeLine = $content[$content.IndexOf($line) + 2]
            $varType = if ($typeLine -match 'type\s*=\s*(.*)') { $matches[1].PadRight($varTypeWidth) } else { "unknown".PadRight($varTypeWidth) }

            # Find default value
            $defaultLine = $content[$content.IndexOf($line) + 3]
            $varDefault = if ($defaultLine -match 'default\s*=\s*(.*)') { $matches[1].PadRight($defaultValueWidth) } else { "null".PadRight($defaultValueWidth) }

            $required = if ($varDefault.Trim() -eq "null") { "No".PadRight($requiredWidth) } else { "Yes".PadRight($requiredWidth) }

            $inputRow = "| $varName | $varDesc | $varType | $varDefault | $required |"
            $inputRow | Out-File -Append -Encoding utf8 -FilePath ..\$READMEFile
        }
    }
}

# Outputs section
@"
## Outputs

| Output Name      | Description                            |
|------------------|----------------------------------------|
"@ | Out-File -Append -Encoding utf8 -FilePath ..\$READMEFile

# Extract outputs
Get-ChildItem -Filter "*.tf" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName

    foreach ($line in $content) {
        if ($line -match 'output "(.*)"') {
            $outName = $matches[1]

            # Find description
            $descLine = $content[$content.IndexOf($line) + 1]
            if ($descLine -match 'description "(.*)"') {
                $outDesc = $matches[1]
                $outputRow = "| $outName | $outDesc |"
                $outputRow | Out-File -Append -Encoding utf8 -FilePath ..\$READMEFile
            }
        }
    }
}

# Finish the README
@"
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
"@ | Out-File -Append -Encoding utf8 -FilePath ..\$READMEFile

Write-Host "README.md has been created successfully."