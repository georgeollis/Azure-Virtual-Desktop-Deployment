targetScope = 'resourceGroup'

@sys.description('Required. The name of the workspace to be attach to new Application Group.')
param name string

@sys.description('Optional. Location for all resources.')
param location string = resourceGroup().location

@sys.description('Optional. The friendly name of the Workspace to be created.')
param friendlyName string?

@sys.description('Optional. The description of the Workspace to be created.')
param description string?

@sys.description('Optional. Resource IDs for the existing Application groups this workspace will group together.')
param appGroupResourceIds array = []

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2022-09-09' = {
  name: name
  location: location
  properties: {
    friendlyName: friendlyName
    description: description
    applicationGroupReferences: !empty(appGroupResourceIds) ? appGroupResourceIds : []
  }
}
