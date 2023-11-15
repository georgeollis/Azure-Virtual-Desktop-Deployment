targetScope = 'resourceGroup'

type destinationsType = {
  logAnalytics: {
    name: string
    workspaceResourceId: string
  }[]?
}

type dataFlowsType = {
  builtInTransform: string?
  destinations: array?
  outputStream: string?
  streams: array?
  transformKql: string?
}[]

type peformanceCounterType = {
  counterSpecifiers: array
  name: string
  samplingFrequencyInSeconds: int
  streams: array
}[]

type windowsEventlogType = {
  name: string
  streams: array
  xPathQueries: array
}[]

@description('The name of the data collection rule.')
param name string

@description('The location of the resource being deployed. Defaults to the resource group location.')
param deploymentLocation string = resourceGroup().location

@description('Is the data collection rule for Linux or Windows? Defaults to Windows')
param kind string = 'Windows'

@description('Destinations of data being collected. Configured for LA workspaces currently.')
param destinations destinationsType

@description('Peformance counters to collect. AVD Optimized.')
param performanceCounters peformanceCounterType = [
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

@description('Windows Event Logs to capture. Defaults to AVD optimized')
param windowsEventLog windowsEventlogType = [
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

@description('Controls the flow of data collection. Defaults to Microsoft-Perf and Microsoft-Event. AVD Optimized.')
param dataFlows dataFlowsType

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: name
  location: deploymentLocation
  kind: kind

  properties: {

    destinations: {
      logAnalytics: !(empty(destinations.?logAnalytics)) ? destinations.logAnalytics : null
    }

    dataSources: {
      performanceCounters: !(empty(performanceCounters)) ? performanceCounters : null
      windowsEventLogs: (!empty(windowsEventLog)) ? windowsEventLog : null
    }

    dataFlows: !(empty(dataFlows)) ? dataFlows : null

  }
}

output name string = dataCollectionRule.name
output id string = dataCollectionRule.id
