targetScope = 'resourceGroup'

@sys.description('Agent update type')
type agentUpdateType = {
  maintenanceWindows: { dayOfWeek: string?, hour: int? }[]?
  type: string?
  maintenanceWindowTimeZone: string?
  useSessionHostLocalTime: bool?
}

type workspaceType = { 
  name: string
  description: string?
  friendlyName: string?
}

type hostpoolType = {
  name: string
  agentUpdate: agentUpdateType?
  hostPoolType: 'Personal' | 'Pooled'
  loadBalancerType: 'BreadthFirst' | 'DepthFirst' | 'Persistent'
  preferredAppGroupType: 'Desktop' | 'None' | 'RailApplications'
  personalDesktopAssignmentType: 'Automatic' | 'Direct'?
  startVMonConnect: bool?
  maxSessionLimit: int?
  friendlyName: string?
  description: string?
  customRdpProperty: string?
  validationEnvironment: bool?
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

@sys.description('The location for deployed resources')
param deploymentLocation string = resourceGroup().location

param workspaceProperties workspaceType

param hostPoolProperties hostpoolType

@sys.description('Application group object that will be assigned to the hostpool.')
param applicationGroupPropeties applicationGroupType

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2023-07-07-preview' = {
  name: hostPoolProperties.name
  location: deploymentLocation
  properties: {
    hostPoolType: hostPoolProperties.hostPoolType
    loadBalancerType: hostPoolProperties.loadBalancerType
    preferredAppGroupType: hostPoolProperties.?preferredAppGroupType ?? 'Desktop'
    personalDesktopAssignmentType: any(hostPoolProperties.?personalDesktopAssignmentType)
    startVMOnConnect: hostPoolProperties.?startVMonConnect ?? false
    maxSessionLimit: hostPoolProperties.?maxSessionLimit
    friendlyName: hostPoolProperties.?friendlyName
    description: hostPoolProperties.?description
    customRdpProperty: hostPoolProperties.?customRdpProperty
    validationEnvironment: hostPoolProperties.?validationEnvironment ?? false
    agentUpdate:  {
      maintenanceWindows: [for window in any(hostPoolProperties.agentUpdate.?maintenanceWindows): {
        dayOfWeek: window.?dayOfWeek 
        hour: window.?hour
      }]
       maintenanceWindowTimeZone: hostPoolProperties.agentUpdate.?maintenanceWindowTimeZone
       type: hostPoolProperties.agentUpdate.?type ?? 'Default'
       useSessionHostLocalTime: hostPoolProperties.agentUpdate.?useSessionHostLocalTime ?? true
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
  name: workspaceProperties.name
  location: deploymentLocation
  properties: {
    friendlyName: workspaceProperties.?friendlyName
    description: workspaceProperties.?description
    applicationGroupReferences: [for (item, index) in applicationGroupPropeties : appg[index].id ]
  }
}

module role 'avd-access.bicep' = [for (item, index) in applicationGroupPropeties: if (item.?principals != null) {
  name: guid('role-assignment-${item.name}-${item.applicationGroupType}')
  params: {
    applicationGroupName: item.name
    principals: any(item.?principals)
  }
  dependsOn: appg
}]

module apps 'avd-applications.bicep' = [ for (item, index) in applicationGroupPropeties: if (item.applicationGroupType != 'Desktop') {
  name: 'deployment-${item.name}'
  params: {
     applicationGroupName: item.name
     applications: any(item.?applications)
  }
  dependsOn: appg
}]

@sys.description('The name of the resource')
output name string = hostpool.name
@sys.description('The resource Id.')
output id string = hostpool.id

output applicationGroupIds array = [for (item, index) in applicationGroupPropeties : {
  id: appg[index].id
}]
