param location string = resourceGroup().location
param subnetId string

module asg1 '../modules/ASG/asg.bicep' = {
  name: 'asg1Deployment'
  params: {
    asgName: 'my-asg'
    location: location
  }
}

module asg2 '../modules/ASG/asg.bicep' = {
  name: 'asg2Deployment'
  params: {
    asgName: 'my-asg'
    location: location
  }
}

module nicModule '../modules/NIC/nic.bicep' = {
  name: 'nicDeployment'
  params: {
    nicName: 'my-nic'
    location: location
    subnetId: subnetId
    asgIds: [
      asg1.outputs.asgId
      asg2.outputs.asgId
    ]
  }
}

// 1. IP Prefix only
// module rule3 '../modules/NSGRULE/nsgrule.bicep'= {
//   name: 'allow-http'
//   params: {
//     nsgName: 'my-nsg'
//     ruleName: 'AllowHttpInbound'
//     priority: 100
//     access: 'Allow'
//     direction: 'Inbound'
//     protocol: 'Tcp'
//     sourcePortRange: '*'
//     destinationPortRange: '80'
//     sourceAddressPrefix: 'Internet'
//     // ASG arrays empty = disabled
//   }
// }

// 2. Multiple prefixes (no for needed)
// module rule4 '../modules/NSGRULE/nsgrule.bicep'= {
//   name: 'allow-multiple-subnets'
//   params: {
//     nsgName: 'my-nsg'
//     ruleName: 'AllowMultipleSubnets'
//     priority: 200
//     access: 'Allow'
//     direction: 'Inbound'
//     protocol: '*'
//     sourceAddressPrefixes: [
//       '10.0.1.0/24'
//       '10.0.2.0/24'
//     ]
//   }
// }

// 3. ASG only (pass pre-built array from parent)
module rule1 '../modules/NSGRULE/nsgrule.bicep' = {
  name: 'asg-rule'
  params: {
    nsgName: 'my-nsg'
    ruleName: 'AllowManagementPortsrule1'
    priority: 2001
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
    destinationPortRanges: [
      '3343'
      '135'
      '49152-65535'
      '445'
      '5022'
    ]
    sourcePortRange: '*'
    sourceApplicationSecurityGroups: [
      {
        id: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/applicationSecurityGroups/web-asg'
      }
    ]
    destinationApplicationSecurityGroups: [
      {
        id: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/applicationSecurityGroups/web-asg'
      }
    ]
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}


module rule2 '../modules/NSGRULE/nsgrule.bicep' = {
  name: 'asg-rule2'
  params: {
    nsgName: 'my-nsg'
    ruleName: 'AllowManagementPortsrule2'
    priority: 2002
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Icmp'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceApplicationSecurityGroups: [
      {
        id: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/applicationSecurityGroups/web-asg'
      }
    ]
    destinationApplicationSecurityGroups: [
      {
        id: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/applicationSecurityGroups/web-asg'
      }
    ]
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}
