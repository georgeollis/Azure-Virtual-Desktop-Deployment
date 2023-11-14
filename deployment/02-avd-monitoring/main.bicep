targetScope = 'subscription'

param deploymentLocation string = deployment().location

var avd_monitoring_objects = {
    
    workspaceObject: {
      workspaceName: 'dev-avd-poc-uks-log'
      deploymentLocation: deploymentLocation
    }

    dataCollectionRuleObject: {
      name: 'dev-avd-poc-uks-dcr'
      kind: 'Windows'
      deploymentLocation: deploymentLocation
      streams: [
        'Microsoft-Perf'
        'Microsoft-Event'
      ]
      windowsEventLog: [
        {
          name: 'events'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'System!*'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'Application!*[System[(Level=2 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
          ]
        }
      ]
      performanceCounters: [
        {
          name: 'perfCounterDataSource10'
          counterSpecifiers: [
            '\\LogicalDisk(C:)\\Avg. Disk Queue Length'
            '\\LogicalDisk(C:)\\Current Disk Queue Length'
            '\\Memory\\Available Mbytes'
            '\\Memory\\Page Faults/sec'
            '\\Memory\\Pages/sec'
            '\\Memory\\% Committed Bytes In Use'
            '\\PhysicalDisk(*)\\Avg. Disk Queue Length'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Read'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Transfer'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Write'
            '\\Processor Information(_Total)\\% Processor Time'
            '\\User Input Delay per Process(*)\\Max Input Delay'
            '\\User Input Delay per Session(*)\\Max Input Delay'
            '\\RemoteFX Network(*)\\Current TCP RTT'
            '\\RemoteFX Network(*)\\Current UDP Bandwidth'
          ]
          samplingFrequencyInSeconds: 30
          streams: [
            'Microsoft-Perf'
          ]
        }
        {
          name: 'perfCounterDataSource30'
          counterSpecifiers: [
            '\\LogicalDisk(C:)\\% Free Space'
            '\\LogicalDisk(C:)\\Avg. Disk sec/Transfer'
            '\\Terminal Services(*)\\Active Sessions'
            '\\Terminal Services(*)\\Inactive Sessions'
            '\\Terminal Services(*)\\Total Sessions'
          ]
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-Perf'
          ]
        }
      ]
      
    }

}

var resourceGroupObject = {
  name: 'dev-avd-poc-svcs-rg'
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

module avd_monitoring_workspace '../../modules/Microsoft.DesktopVirtualization/avd-la-workspace.bicep' = {
  name: 'avd-monitoring-workspace'
  params: {
    name: avd_monitoring_objects.workspaceObject.workspaceName
    deploymentLocation: avd_monitoring_objects.workspaceObject.deploymentLocation
  }
  scope: resourceGroup
}

module avd_monitoring_dcr '../../modules/Microsoft.DesktopVirtualization/avd-data-collection-rule.bicep' = {
  scope: resourceGroup
  name: 'avd-monitoring-dcr'
  params: {
    name: avd_monitoring_objects.dataCollectionRuleObject.name
    kind: avd_monitoring_objects.dataCollectionRuleObject.kind
    deploymentLocation: avd_monitoring_objects.dataCollectionRuleObject.deploymentLocation
    destinations: {
      logAnalytics: [
        {
          name: avd_monitoring_objects.workspaceObject.workspaceName
          workspaceResourceId: avd_monitoring_workspace.outputs.workspaceId
        }
      ]
    }
    dataFlows: [
      {
        destinations: [
          avd_monitoring_objects.workspaceObject.workspaceName
        ]
        streams: avd_monitoring_objects.dataCollectionRuleObject.streams
      }
    ]
    windowsEventLog: avd_monitoring_objects.dataCollectionRuleObject.windowsEventLog
    performanceCounters: avd_monitoring_objects.dataCollectionRuleObject.performanceCounters
    
  }
}

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output deploymentLocation string = deploymentLocation
