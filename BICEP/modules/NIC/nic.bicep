param nicName string
param location string
param subnetId string
param asgIds array  // creating multiple ASGs for Single NIC

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          applicationSecurityGroups: [
            for asgId in asgIds: {
              id: asgId
            }
          ]
        }
      }
    ]
  }
}

output nicId string = nic.id
