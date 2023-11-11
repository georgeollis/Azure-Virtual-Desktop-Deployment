type applicationType = {
  name: string // Required
  commandLineSetting: 'Allow' | 'DoNotAllow' | 'Require' // Required
  applicationType: 'InBuilt' | 'MsixApplication'
  commandLineArguements: string?// Optional
  filePath: string?// Optional
  description: string?// Optional
  iconPath: string?// Optional
  iconIndex: int?// Optional
  friendlyName: string?
  msixPackageApplicationId: string?// Optional
  msixPackageFamilyName: string?// Optional
  showInPortal: bool?// Optional
}[]

param applicationGroupName string

param applications applicationType

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' existing = {
  name: applicationGroupName
}

resource apps 'Microsoft.DesktopVirtualization/applicationGroups/applications@2023-09-05' = [for app in applications: {
  parent: applicationGroup
  name: app.name
  properties: {
    commandLineSetting: app.commandLineSetting
    applicationType: app.applicationType
    commandLineArguments: app.?commandLineArguements
    description: app.?description
    filePath: app.?filePath
    friendlyName: app.?friendlyName
    iconIndex: app.?iconIndex
    iconPath: app.?iconPath
    msixPackageApplicationId: app.?msixPackageApplicationId
    msixPackageFamilyName: app.?msixPackageFamilyName
    showInPortal: app.?showInPortal ?? true
  }
}]
