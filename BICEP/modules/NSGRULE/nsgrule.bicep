param nsgName string
param ruleName string
param priority int
@allowed(['Allow', 'Deny'])
param access string
@allowed(['Inbound', 'Outbound'])
param direction string
@allowed(['*', 'Any', 'Esp', 'Icmp', 'Tcp', 'Udp'])
param protocol string

param sourcePortRange string = '*'
param destinationPortRange string = '*'

param sourcePortRanges array = []
param destinationPortRanges array = []

// Prefix or ASG - pass arrays directly (no for-expressions needed)
param sourceAddressPrefix string = '*'
param sourceAddressPrefixes array = [] // For multiple prefixes
param sourceApplicationSecurityGroups array = [] // Pass pre-built ASG array

param destinationAddressPrefix string = '*'
param destinationAddressPrefixes array = []
param destinationApplicationSecurityGroups array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' existing = {
  name: nsgName
}

resource nsgRule 'Microsoft.Network/networkSecurityGroups/securityRules@2025-05-01' = {
  name: ruleName
  parent: nsg
  properties: {
    priority: priority
    access: access
    direction: direction
    protocol: protocol
    sourcePortRange: !empty(sourcePortRanges) ? null : sourcePortRange
    sourcePortRanges: !empty(sourcePortRanges) ? sourcePortRanges : null

    destinationPortRange: !empty(destinationPortRanges) ? null : destinationPortRange
    destinationPortRanges: !empty(destinationPortRanges) ? destinationPortRanges : null

    sourceAddressPrefix: !empty(sourceAddressPrefixes) || !empty(sourceApplicationSecurityGroups) ? null : sourceAddressPrefix
    sourceAddressPrefixes: !empty(sourceAddressPrefixes) ? sourceAddressPrefixes : null
    sourceApplicationSecurityGroups: !empty(sourceApplicationSecurityGroups) ? sourceApplicationSecurityGroups : null

    destinationAddressPrefix: !empty(destinationAddressPrefixes) || !empty(destinationApplicationSecurityGroups) ? null : destinationAddressPrefix
    destinationAddressPrefixes: !empty(destinationAddressPrefixes) ? destinationAddressPrefixes : null
    destinationApplicationSecurityGroups: !empty(destinationApplicationSecurityGroups) ? destinationApplicationSecurityGroups : null
  }
}
