targetScope = 'resourceGroup'

param location string = resourceGroup().location

var serviceObjects = [
  {
    hostPoolProperties: {
      hostPoolType: 'Pooled'
      deploymentLocation: location
      loadBalancerType: 'BreadthFirst'
      preferredAppGroupType: 'Desktop'
      maxSessionLimit: 10
      agentUpdate: {
        maintenanceWindows: [ { dayOfWeek: 'Sunday', hour: 1 }, { dayOfWeek: 'Tuesday', hour: 3 } ]
        type: 'Scheduled'
        useSessionHostLocalTime: false
        maintenanceWindowTimeZone: 'UTC+12'
      }
      name: 'hostppol122-po1w132'
    }
    applicationGroupPropeties: [ {
        name: 'appg1501'
        applicationGroupType: 'Desktop'
        deploymentLocation: location
        principals: [
          '13f94c0d-8a51-492a-928b-59392c23c1ac'
        ]
      }
      {
        name: 'app1511'
        applicationGroupType: 'RemoteApp'
        deploymentLocation: location
        principals: [
          '13f94c0d-8a51-492a-928b-59392c23c1ac'
        ]
        applications: [
          {
            applicationType: 'InBuilt'
            commandLineSetting: 'DoNotAllow'
            name: 'google-chrome'
            filePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe'
          }
          {
            applicationType: 'InBuilt'
            commandLineSetting: 'DoNotAllow'
            name: 'Notepad'
            filePath: 'C:\\Program Files\\Google\\Chrome\\Application\\notepad.exe'
          }
        ]
      }
    ]
    workspaceProperties: {
      name: 'workspace-01'      
    }
  }
]

module so '../modules/Microsoft.DesktopVirtualization/avd-service-objects.bicep' = [for service in serviceObjects: {
  name: 'deploy-avd-${service.workspaceProperties.name}'
  params: {
    workspaceProperties: service.workspaceProperties
    hostPoolProperties: service.hostPoolProperties
    applicationGroupPropeties: service.applicationGroupPropeties
    deploymentLocation: location
    diagnosticSettings: {
      name: 'logging1'
      workspaceId: '/subscriptions/baba41cf-c01d-4a55-b6c5-ca494b802be5/resourcegroups/adadawdad/providers/microsoft.operationalinsights/workspaces/log122132123'
    }
  }
}]
