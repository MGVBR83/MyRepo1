#!/bin/bash

README_FILE="README.md"

# Create or clear the README file
echo "# Terraform Configuration" > $README_FILE
echo "" >> $README_FILE

# Add Overview
echo "## Overview" >> $README_FILE
echo "This Terraform configuration is used to ..." >> $README_FILE
echo "" >> $README_FILE

# Add Usage
echo "## Usage" >> $README_FILE
echo "\`\`\`hcl" >> $README_FILE
echo "terraform init" >> $README_FILE
echo "terraform apply" >> $README_FILE
echo "\`\`\`" >> $README_FILE
echo "" >> $README_FILE

# Add Inputs
echo "## Inputs" >> $README_FILE
echo "| Name | Description | Type | Default | Required |" >> $README_FILE
echo "|------|-------------|------|---------|----------|" >> $README_FILE

# Loop through Terraform variables to populate Inputs
for var in $(terraform output -json | jq -r 'keys[]'); do
  description=$(terraform validate | grep "$var" | awk '{print $2}')
  type="string"  # Modify as needed
  default=$(terraform output "$var" | jq -r '.default' || echo "N/A")
  required="Yes"

  echo "| $var | $description | $type | $default | $required |" >> $README_FILE
done

echo "" >> $README_FILE

# Add Outputs
echo "## Outputs" >> $README_FILE
for output in $(terraform output -json | jq -r 'keys[]'); do
  description=$(terraform output "$output" | jq -r '.description' || echo "N/A")
  echo "- $output: $description" >> $README_FILE
done

echo "" >> $README_FILE

# Add Examples
echo "## Examples" >> $README_FILE
echo "```hcl" >> $README_FILE
echo "# Example usage of this configuration" >> $README_FILE
echo "```" >> $README_FILE

echo "README file has been updated successfully."
