targetScope = 'resourceGroup'

param deploymentLocation string = resourceGroup().location

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

module so '../../modules/Microsoft.DesktopVirtualization/avd-service-objects.bicep' = [for service in serviceObjects: {
  name: 'deploy-avd-${service.workspaceProperties.name}'
  params: {
    workspaceProperties: service.workspaceProperties
    hostPoolProperties: service.hostPoolProperties
    applicationGroupPropeties: service.applicationGroupPropeties
    deploymentLocation: deploymentLocation
  }
}]

output resourceGroupName string = resourceGroup().name
output resourceGroupId string = resourceGroup().id
output deploymentLocation string = deploymentLocation

output serviceObjects array = [for (item, index) in serviceObjects: {
  workspaceName: so[index].outputs.workspaceName
  workspaceId: so[index].outputs.workspaceId
  hostPoolName: so[index].outputs.hostPoolName
  hostPoolId: so[index].outputs.hostPoolId
  applicationGroupNames: so[index].outputs.applicationGroupNames
  applicationGroupIds: so[index].outputs.applicationGroupIds
}]
