targetScope = 'subscription'

param deploymentLocation string = deployment().location

var serviceObjects = [
  {

    hostPoolProperties: {
      name: 'dev-avd-poc-uks-hp-01'
      hostPoolType: 'Pooled'
      deploymentLocation: deploymentLocation
      loadBalancerType: 'BreadthFirst'
      preferredAppGroupType: 'Desktop'
      maxSessionLimit: 10
      agentUpdate: {
        maintenanceWindows: [ { dayOfWeek: 'Sunday', hour: 1 }, { dayOfWeek: 'Tuesday', hour: 3 } ]
        type: 'Scheduled'
        useSessionHostLocalTime: false
        maintenanceWindowTimeZone: 'UTC+12'
      }
    }


    applicationGroupPropeties: [ {
        name: 'dev-avd-poc-desktop-uks-ag-01'
        applicationGroupType: 'Desktop'
        deploymentLocation: deploymentLocation
        principals: [
          '13f94c0d-8a51-492a-928b-59392c23c1ac'
        ]
      }
    ]


    workspaceProperties: {
      name: 'dev-avd-poc-uks-ws-01'      
    }
  }
]

var resourceGroupObject = {
  name: 'dev-avd-poc-serviceobjects-uks-rg'
  location: deploymentLocation
  tags: {
    POC: 'AVD'
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
  tags: resourceGroupObject.tags
}


module avd_service_objects '../../modules/avd-service-objects.bicep' = [for (service, index) in serviceObjects: {
  name: 'deploy-avd-service-objects-${index}'
  params: {
    workspaceProperties: service.workspaceProperties
    hostPoolProperties: service.hostPoolProperties
    applicationGroupPropeties: service.applicationGroupPropeties
    deploymentLocation: deploymentLocation
    tags: resourceGroupObject.tags
  }
  scope: resourceGroup
}]

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output deploymentLocation string = deploymentLocation

output avd_service_objects array = [for (item, index) in serviceObjects: {
  workspaceName: avd_service_objects[index].outputs.workspaceName
  workspaceId: avd_service_objects[index].outputs.workspaceId
  hostPoolName: avd_service_objects[index].outputs.hostPoolName
  hostPoolId: avd_service_objects[index].outputs.hostPoolId
  applicationGroupNames: avd_service_objects[index].outputs.applicationGroupNames
  applicationGroupIds: avd_service_objects[index].outputs.applicationGroupIds
}]
