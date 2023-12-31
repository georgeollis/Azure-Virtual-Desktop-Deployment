targetScope = 'resourceGroup'

type diagnosticSettingsType = {
  name: string?
  workspaceId: string?
  storageAccountId: string?
  eventHubAuthorizationRuleId: string? 
  eventHubName: string?
  retentionPolicy: int?
}

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

@description('(Optional) - The location of the resource being deployed. Defaults to the resource group location.')
param deploymentLocation string = resourceGroup().location

@description('(Required) - The properties of the workspace being created. One workspace will be created.')
param workspaceProperties workspaceType

@description('(Required) - The hostpool properties. One hostpool will be created.')
param hostPoolProperties hostpoolType

@description('(Required) - A list of applicationGroupProperties. Multiple application groups can be deployed.')
param applicationGroupPropeties applicationGroupType

@description('(Optional) - Should diagnostic settings be configured for service objects. Hostpool, workspace and application groups? Defaults to no.')
param diagnosticSettings diagnosticSettingsType?

@description('(Optional - Tags to be added on resources.)')
param tags object?

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2023-07-07-preview' = {
  name: hostPoolProperties.name
  location: deploymentLocation
  tags: tags
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
  tags: tags
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
  tags: tags
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

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticSettings)) {
  name: diagnosticSettings.?name ?? 'logging'
  scope: workspace
  properties: {
    eventHubAuthorizationRuleId: diagnosticSettings.?eventHubAuthorizationRuleId
    eventHubName: diagnosticSettings.?eventHubName
    workspaceId: diagnosticSettings.?workspaceId
    storageAccountId: diagnosticSettings.?storageAccountId
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
    ]
  }
}

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticSettings)) {
  name: diagnosticSettings.?name ?? 'logging'
  scope: hostpool
  properties: {
    eventHubAuthorizationRuleId: diagnosticSettings.?eventHubAuthorizationRuleId
    eventHubName: diagnosticSettings.?eventHubName
    workspaceId: diagnosticSettings.?workspaceId
    storageAccountId: diagnosticSettings.?storageAccountId
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
    ]
  }
}

resource applicationGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, index) in applicationGroupPropeties: if (!empty(diagnosticSettings)) {
  name: diagnosticSettings.?name ?? 'logging'
  scope: appg[index]
  properties: {
    eventHubAuthorizationRuleId: diagnosticSettings.?eventHubAuthorizationRuleId
    eventHubName: diagnosticSettings.?eventHubName
    workspaceId: diagnosticSettings.?workspaceId
    storageAccountId: diagnosticSettings.?storageAccountId
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
    ]
  }
}]


output applicationGroupIds array = [for (item, index) in applicationGroupPropeties : {
  id: appg[index].id
}]

output applicationGroupNames array = [for (item, index) in applicationGroupPropeties : {
  id: appg[index].name
}]

output hostPoolName string = hostpool.name
output hostPoolId string = hostpool.id
output workspaceName string = workspace.name
output workspaceId string = workspace.id
