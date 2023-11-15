@description('List of principal ids that require access to Azure Virtual Desktop.')
param principals array 

@description('The name of the application group that access will be applied.')
param applicationGroupName string

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' existing = {
  name: applicationGroupName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [ for principal in principals : {
  name: guid(uniqueString('${applicationGroupName}-role-assignment-${principal}'))
  properties: {
    principalId: principal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63') // Desktop Virtualization User 
  }
  scope: applicationGroup
}]
