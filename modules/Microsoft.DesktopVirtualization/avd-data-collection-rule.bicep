targetScope = 'resourceGroup'

type destinationsType = {
  logAnalytics: {
    name: string
    workspaceId: string
  }[]?
}

type peformanceCounterType = {
  counterSpecifiers: array
  name: string
  samplingFrequencyInSeconds: int
  streams: array
}[]?

type windowsEventlogType = { 
  name: string
  streams: array
  xPathQueries: array
}[]

param name string

param deploymentLocation string = resourceGroup().location

param kind string

param destinations destinationsType

param performanceCounters peformanceCounterType

param windowsEventLog windowsEventlogType

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: name
  location: deploymentLocation
  kind: kind
  
  properties: {
    
    destinations: {
      logAnalytics: !empty(destinations.?logAnalytics) ? destinations.logAnalytics : null
    }

    dataSources: {
      performanceCounters: [for (item, index) in any(performanceCounters): {
        counterSpecifiers: item.counterSpecifiers
        name: item.name
        samplingFrequencyInSeconds: item.samplingFrequencyInSeconds
        streams: item.streams
      }]

      windowsEventLogs: [ for (item, index) in any(windowsEventLog) : {
        name: item.name
        streams: item.streams
        xPathQueries: item.xPathQueries
      }]

    }

}
}
