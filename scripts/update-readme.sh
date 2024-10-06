#!/bin/bash

README_FILE="README.md"
TF_FILES="workload/*.tf"

# Create or clear the README file
echo "# Terraform Configuration" > $README_FILE
echo "" >> $README_FILE

# Add Overview
echo "## Overview" >> $README_FILE
echo "This Terraform configuration sets up XYZ resources." >> $README_FILE
echo "" >> $README_FILE

# Add Usage
echo "## Usage" >> $README_FILE
echo "\`\`\`bash" >> $README_FILE
echo "terraform init" >> $README_FILE
echo "terraform apply" >> $README_FILE
echo "\`\`\`" >> $README_FILE
echo "" >> $README_FILE

# Add Inputs Section
echo "## Inputs" >> $README_FILE
echo "| Name | Description | Type | Default | Required |" >> $README_FILE
echo "|------|-------------|------|---------|----------|" >> $README_FILE

# Extract variables from .tf files
for file in $TF_FILES; do
  # Find variable blocks
  grep -E 'variable ".*"' "$file" | while read -r line; do
    var_name=$(echo $line | sed 's/variable "\(.*\)"/\1/')
    description=$(grep -A 1 "$line" "$file" | grep 'description' | sed 's/description = "\(.*\)"/\1/')
    type=$(grep -A 1 "$line" "$file" | grep 'type' | sed 's/type = \(.*\)/\1/' || echo "string")
    default=$(grep -A 1 "$line" "$file" | grep 'default' | sed 's/default = "\(.*\)"/\1/' || echo "N/A")
    required=$(grep -A 1 "$line" "$file" | grep 'optional' || echo "Yes")

    echo "| $var_name | $description | $type | $default | $required |" >> $README_FILE
  done
done

echo "" >> $README_FILE

# Add Outputs Section
echo "## Outputs" >> $README_FILE
for output in $(terraform output -json | jq -r 'keys[]'); do
  description=$(terraform output "$output" | jq -r '.description' || echo "N/A")
  echo "- $output: $description" >> $README_FILE
done

echo "" >> $README_FILE

# Add Examples Section
echo "## Examples" >> $README_FILE
echo "```hcl" >> $README_FILE
echo "# Example usage of this configuration" >> $README_FILE
echo "```" >> $README_FILE

echo "README file has been generated successfully."
