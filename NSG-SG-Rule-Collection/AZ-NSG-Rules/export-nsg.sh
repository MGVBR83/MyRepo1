#!/bin/bash
NSG_NAME="$1"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Azure_Rule_ID,Subscription,Resource_Group,Server_Name_Asset,NIC_Subnet_Scope,NSG_Name,NSG_Rule_Name,Priority,Direction,Access,Protocol,Source,Source_Ports,Destination,Destination_Ports,Description,Notes" > azure_nsg_rules.csv

az network nsg rule list \
  --nsg-name "$NSG_NAME" \
  --query "[].{
    'Azure_Rule_ID': name,
    'Subscription': '$SUBSCRIPTION_ID',
    'Resource_Group': resourceGroup,
    'Server_Name_Asset': null,
    'NIC_Subnet_Scope': null,
    'NSG_Name': '$NSG_NAME',
    'NSG_Rule_Name': name,
    'Priority': priority,
    'Direction': direction,
    'Access': access,
    'Protocol': protocol,
    'Source': sourceAddressPrefix,
    'Source_Ports': sourcePortRange,
    'Destination': destinationAddressPrefix,
    'Destination_Ports': destinationPortRange,
    'Description': null
  }" \
  --output table >> azure_nsg_rules.csv

echo "Exported $NSG_NAME rules to azure_nsg_rules.csv"
