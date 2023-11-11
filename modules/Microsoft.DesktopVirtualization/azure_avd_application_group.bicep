type applicationGroupType = {
  deploymentLocation: string
  applicationGroupType: 'Desktop' | 'RemoteApp'
  friendlyName: string?
  description: string?
  hostPoolArmPath: string
  name: string
  identity: {
    type: string?
  }
}

param applicationGroupPropeties applicationGroupType

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: applicationGroupPropeties.name
  properties: {
    applicationGroupType: applicationGroupPropeties.applicationGroupType
    hostPoolArmPath: applicationGroupPropeties.hostPoolArmPath
    description: applicationGroupPropeties.?description
    friendlyName: applicationGroupPropeties.?friendlyName
  }
  location: applicationGroupPropeties.deploymentLocation
  identity: applicationGroupPropeties.?identity
}

