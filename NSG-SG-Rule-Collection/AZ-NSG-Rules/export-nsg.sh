#!/bin/bash

set -euo pipefail

NSG_NAME="${1:-}"
RESOURCE_GROUP="${2:-}"

if [[ -z "$NSG_NAME" || -z "$RESOURCE_GROUP" ]]; then
  echo "Usage: $0 <nsg-name> <resource-group>"
  exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Azure_Rule_ID,Subscription,Resource_Group,Server_Name_Asset,NIC_Subnet_Scope,NSG_Name,NSG_Rule_Name,Priority,Direction,Access,Protocol,Source,Source_Ports,Destination,Destination_Ports,Description,Notes" > azure_nsg_rules.csv

az network nsg rule list \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --query "[].[
    name,
    '$SUBSCRIPTION_ID',
    resourceGroup,
    '',
    '',
    '$NSG_NAME',
    name,
    to_string(priority),
    direction,
    access,
    protocol,
    join(';', ([sourceAddressPrefix] || `[]`) + (sourceAddressPrefixes || `[]`)),
    join(';', ([sourcePortRange] || `[]`) + (sourcePortRanges || `[]`)),
    join(';', ([destinationAddressPrefix] || `[]`) + (destinationAddressPrefixes || `[]`)),
    join(';', ([destinationPortRange] || `[]`) + (destinationPortRanges || `[]`)),
    description || '',
    ''
  ]" \
  --output tsv | sed 's/\t/","/g; s/^/"/; s/$/"/' >> azure_nsg_rules.csv

echo "Exported $NSG_NAME rules to azure_nsg_rules.csv"
