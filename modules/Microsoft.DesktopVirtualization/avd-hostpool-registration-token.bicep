param baseTime string = utcNow('u')

@description('(Required) - Hostpool name')
param hostPoolName string

@description('(Optional) - The deployment location of resources. Defaults to the location of the resource group.')
param deploymentLocation string = resourceGroup().location

@description('(Required) - Host pool type')
param hostPoolType string

@description('(Required) - The Host pool load balancer type.')
param loadBalancerType string

@description('(Required) - The prefereed application group type.')
param preferredAppGroupType string

var expirationTime = dateTimeAdd(baseTime, 'PT48H')

// This module simply provides default values for an already exisiting hostpool. The purpose of this module is to ONLY generate new registration tokens. !!!!!
// IMPORTANT
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

resource hostPoolRegistration 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = { 
  name: hostPoolName
  location: deploymentLocation
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType:  loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    registrationInfo: {
      expirationTime: expirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

output registrationInfoToken string = reference(hostPoolRegistration.id).registrationInfo.token
