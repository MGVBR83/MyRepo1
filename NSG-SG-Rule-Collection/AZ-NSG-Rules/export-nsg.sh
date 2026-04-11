#!/bin/bash
set -euo pipefail

NSG_NAME="${1:-}"
RESOURCE_GROUP="${2:-}"

if [[ -z "$NSG_NAME" || -z "$RESOURCE_GROUP" ]]; then
  echo "Usage: $0 <nsg-name> <resource-group>"
  exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Azure_Rule_ID,Subscription,Resource_Group,NSG_Name,NSG_Rule_Name,Priority,Direction,Access,Protocol,Source_Address_Prefix,Source_Address_Prefixes,Source_ASGs,Source_Port,Source_Ports,Destination_Address_Prefix,Destination_Address_Prefixes,Destination_ASGs,Destination_Port,Destination_Ports,Description" > azure_nsg_rules.csv

az network nsg rule list \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --include-default \
  --query "[].[
    name,
    '$SUBSCRIPTION_ID',
    '$RESOURCE_GROUP',
    '$NSG_NAME',
    name,
    to_string(priority),
    direction,
    access,
    protocol,
    sourceAddressPrefix || '',
    join(';', sourceAddressPrefixes || \`[]\`),
    join(';', (sourceApplicationSecurityGroups || \`[]\`) | [].id),
    sourcePortRange || '',
    join(';', sourcePortRanges || \`[]\`),
    destinationAddressPrefix || '',
    join(';', destinationAddressPrefixes || \`[]\`),
    join(';', (destinationApplicationSecurityGroups || \`[]\`) | [].id),
    destinationPortRange || '',
    join(';', destinationPortRanges || \`[]\`),
    description || ''
  ]" \
  --output tsv \
  | awk 'BEGIN{FS="\t"; OFS="\t"} {
      for(i=1; i<=NF; i++) {
        # columns 12 and 17 are ASG fields — extract name after last "/"
        if (i==12 || i==17) {
          n = split($i, parts, ";")
          result = ""
          for(j=1; j<=n; j++) {
            split(parts[j], seg, "/")
            result = result (j>1 ? ";" : "") seg[length(seg)]
          }
          $i = result
        }
      }
      print
    }' \
  | awk 'BEGIN{FS="\t"; OFS=","} {
      for(i=1; i<=NF; i++) {
        gsub(/"/, "\"\"", $i)
        printf "%s\"%s\"", (i>1 ? OFS : ""), $i
      }
      print ""
    }' >> azure_nsg_rules.csv

echo "Exported $NSG_NAME rules to azure_nsg_rules.csv"
