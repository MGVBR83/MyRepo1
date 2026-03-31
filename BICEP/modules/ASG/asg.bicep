param asgName string
param location string

resource asg 'Microsoft.Network/applicationSecurityGroups@2023-05-01' = {
  name: asgName
  location: location
}

output asgId string = asg.id
