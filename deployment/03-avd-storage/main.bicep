targetScope = 'subscription'

param deploymentLocation string = deployment().location

var resourceGroupObject = {
  name: 'dev-avd-poc-shared-services-rg'
  location: deploymentLocation
  tags: {
    POC: 'AVD'
  }
}

var privateEndpointObject =  {
  privateDnsZoneId: '/subscriptions/baba41cf-c01d-4a55-b6c5-ca494b802be5/resourceGroups/adadawdad/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
  subnetId: '/subscriptions/baba41cf-c01d-4a55-b6c5-ca494b802be5/resourceGroups/adadawdad/providers/Microsoft.Network/virtualNetworks/test/subnets/default'
  groupIds: [
    'file'
  ]
}

var storageAccountObject = {
  name: 'asduasudnasst01'
  fileShares: [
    {
      shareName: 'profiles'
      shareQuota: 150
    }
  ]
}

resource avd_storage_resource_group 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
  tags: resourceGroupObject.tags
}

module storageAccount '../../modules/Microsoft.DesktopVirtualization/avd-storage-account.bicep' = {
  name: 'avd-storage-account'
  params: {
    name: storageAccountObject.name
    delpoymentLocation: deploymentLocation
    fileShares: storageAccountObject.fileShares
    tags: resourceGroupObject.tags
  }
  scope: avd_storage_resource_group
}

module privateEndpoint '../../modules/Microsoft.DesktopVirtualization/avd-private-endpoint.bicep' = {
  scope: avd_storage_resource_group
  name: 'avd-storage-private-endpoint'
  params: {
    location: storageAccount.outputs.location
    groupIds: privateEndpointObject.groupIds
    privateDnsZoneId: privateEndpointObject.privateDnsZoneId 
    privateEndpointName: storageAccount.outputs.name
    resourceId: storageAccount.outputs.id
    subnetId: privateEndpointObject.subnetId
  }
}

output storageAccoount object = {
  name: storageAccount.outputs.name
  id: storageAccount.outputs.id
  location: storageAccount.outputs.location
}
