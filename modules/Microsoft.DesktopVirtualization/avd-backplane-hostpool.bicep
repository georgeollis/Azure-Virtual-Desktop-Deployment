targetScope = 'resourceGroup'

@sys.description('Agent update type')
type agentUpdateType = {
  maintenanceWindows: ({ dayOfWeek: string, hour: int })[]?
  type: string?
  maintenanceWindowTimeZone: string?
  useSessionHostLocalTime: bool?
}

@sys.description('Application group type')
type applicationGroupType = {
  deploymentLocation: string
  applicationGroupType: 'Desktop' | 'RemoteApp'
  friendlyName: string?
  description: string?
  name: string
  principals: array?
  applications: {
    name: string // Required
    commandLineSetting: 'Allow' | 'DoNotAllow' | 'Require' // Required
    applicationType: 'InBuilt' | 'MsixApplication'
    commandLineArguements: string?// Optional
    filePath: string? // Optional
    description: string? // Optional
    iconPath: string? // Optional
    iconIndex: int? // Optional
    friendlyName: string?
    msixPackageApplicationId: string? // Optional
    msixPackageFamilyName: string? // Optional
    showInPortal: bool? // Optional
  }[]?
}[]

@sys.description('The session host configuration for updating agent, monitoring agent, and stack component.')
param agentUpdate agentUpdateType = {
  useSessionHostLocalTime: true
  type: 'Scheduled'
  maintenanceWindows: [
    {
      dayOfWeek: 'Sunday'
      hour: 20
    }
  ]
}

@sys.description('(Required) - Name of the hostPool.')
param name string

@sys.description('HostPool type for desktop.')
@allowed([ 'Personal', 'Pooled' ])
param hostPoolType string

@sys.description('(Required) - 	The type of the load balancer.')
@allowed([ 'BreadthFirst', 'DepthFirst', 'Persistent' ])
param loadBalancerType string

@sys.description('(Required) - The type of preferred application group type, default to Desktop Application Group')
@allowed([
  'Desktop'
  'None'
  'RailApplications'
])
param preferredAppGroupType string = 'Desktop'

@sys.description('The geo-location where the resource lives')
param deploymentLocation string = resourceGroup().location

@sys.description('PersonalDesktopAssignment type for HostPool.')
@allowed([ 'Automatic', 'Direct', '' ])
param personalDesktopAssignmentType string = ''

@sys.description('The flag to turn on/off StartVMOnConnect feature.')
param startVMOnConnect bool = false

@sys.description('The max session limit of HostPool.')
param maxSessionLimit int?

@sys.description('Friendly name of HostPool.')
param friendlyName string?

@sys.description('Description of HostPool.')
param description string?

@sys.description('Custom rdp property of HostPool.')
param customRdpProperty string?

@sys.description('Is validation environment.')
param validationEnvironment bool = false

@sys.description('Application group object that will be assigned to the hostpool.')
param applicationGroupPropeties applicationGroupType

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2023-07-07-preview' = {
  name: name
  location: deploymentLocation
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    personalDesktopAssignmentType: any(personalDesktopAssignmentType)
    startVMOnConnect: startVMOnConnect
    maxSessionLimit: maxSessionLimit
    friendlyName: friendlyName
    description: description
    customRdpProperty: customRdpProperty
    validationEnvironment: validationEnvironment
    agentUpdate: {
      maintenanceWindows: [for window in agentUpdate.maintenanceWindows: {
        dayOfWeek: window.dayOfWeek
        hour: window.hour
      }]
      maintenanceWindowTimeZone: agentUpdate.useSessionHostLocalTime == false ? agentUpdate.maintenanceWindowTimeZone : null
      type: agentUpdate.type
      useSessionHostLocalTime: agentUpdate.useSessionHostLocalTime
    }
  }
}

resource appg 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = [for applicationGroup in applicationGroupPropeties: {
  name: applicationGroup.name
  properties: {
    applicationGroupType: applicationGroup.applicationGroupType
    hostPoolArmPath: hostpool.id
    description: applicationGroup.?description
    friendlyName: applicationGroup.?friendlyName
  }
  location: applicationGroup.deploymentLocation
}] 

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2022-09-09' = {
  name: 'workspace-01'
  location: deploymentLocation
  properties: {
    friendlyName: friendlyName
    description: description
    applicationGroupReferences: [for (item, index) in applicationGroupPropeties : appg[index].id ]
  }
}

module role 'avd-backplane-roleassignment.bicep' = [for (item, index) in applicationGroupPropeties: if (item.?principals != null) {
  name: guid('role-assignment-${item.name}-${item.applicationGroupType}')
  params: {
    applicationGroupName: item.name
    principals: any(item.?principals)
  }
}]


module apps 'azure_avd_application_group_applications.bicep' = [ for (item, index) in applicationGroupPropeties: if (item.applicationGroupType != 'Desktop') {
  name: 'deployment-${item.name}'
  params: {
     applicationGroupName: item.name
     applications: any(item.?applications)
  }
}]

@sys.description('The name of the resource')
output name string = hostpool.name
@sys.description('The resource Id.')
output id string = hostpool.id

output applicationGroupIds array = [for (item, index) in applicationGroupPropeties : {
  id: appg[index].id
}]
