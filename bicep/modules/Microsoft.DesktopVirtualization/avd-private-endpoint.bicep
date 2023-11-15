targetScope = 'resourceGroup'

@description('(Required) - The name of the privte endpoint resource.')
param privateEndpointName string

@description('(Required) - The subnet to attach the private endpoint.')
param subnetId string

@description('(Required) - The id of the resource')
param resourceId string

@description('(Required) - The private Dns Zone Id')
param privateDnsZoneId string

@description('(Required) - a list of groupIds for the private resource')
param groupIds string[]

@description('(Optional) - The location of the resource. Defaults tot he resource group location.')
param location string = resourceGroup().location

@description('(Optional) - The tags on the resources')
param tags object?

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  tags: tags
  location: location
  properties: {
    customNetworkInterfaceName: '${privateEndpointName}-nic'
     subnet: { id: subnetId }
     privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-link'
        properties: {
          groupIds: groupIds
          privateLinkServiceId: resourceId
        }
      }
     ]
  }

  resource privateEndpointDns 'privateDnsZoneGroups' = {
    name: '${privateEndpointName}-dns'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: '${privateEndpointName}-dns-config'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}
