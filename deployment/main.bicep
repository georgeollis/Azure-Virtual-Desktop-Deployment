targetScope = 'resourceGroup'

param location string = resourceGroup().location

var poolData = [
  {
    hostPoolType: 'Pooled'
    deploymentLocation: location
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    agentUpdate: {
      maintenanceWindows: [ { dayOfWeek: 'Monday', hour: 1 }, { dayOfWeek: 'Tuesday', hour: 3 } ]
      type: 'Scheduled'
      useSessionHostLocalTime: false
      maintenanceWindowTimeZone: 'UTC+12'
    }
    name: 'hostppol122-po1w132'

    applicationGroupPropeties: [ {
        name: 'appg1'
        applicationGroupType: 'Desktop'
        deploymentLocation: location
        principals: [
          '13f94c0d-8a51-492a-928b-59392c23c1ac'
        ]
      }
      {
        name: 'app5'
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
      {
        name: 'app6'
        applicationGroupType: 'RemoteApp'
        deploymentLocation: location
        principals: [
          '13f94c0d-8a51-492a-928b-59392c23c1ac'
          '10326a23-757e-4cc3-ae93-d5daa5be98d3'
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
          {
            applicationType: 'InBuilt'
            commandLineSetting: 'DoNotAllow'
            name: 'Notepad1'
            filePath: 'C:\\Program Files\\Google\\Chrome\\Application\\notepad.exe'
          }
        ]
      }
    ]
  }
]

module hp '../modules/Microsoft.DesktopVirtualization/avd-backplane-hostpool.bicep' = [for pool in poolData: {
  name: 'deploy-${pool.name}'
  params: {
    name: pool.name
    hostPoolType: pool.hostPoolType
    loadBalancerType: pool.loadBalancerType
    deploymentLocation: pool.deploymentLocation
    agentUpdate: pool.agentUpdate
    applicationGroupPropeties: pool.applicationGroupPropeties
  }
}]
