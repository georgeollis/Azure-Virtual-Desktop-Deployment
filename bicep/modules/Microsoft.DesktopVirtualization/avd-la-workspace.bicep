targetScope = 'resourceGroup'

@description('(Required) - The name of the resource')
param name string

@description('(Optional) - The location of the deployed resource. Defaults to the resource group location.')
param deploymentLocation string = resourceGroup().location

@description('(Optional) - The sku of the workspace. Defaults to PerGB2018')
param sku string = 'PerGB2018'

@description('(Optional) - What is the daily quota limit of data to be ingested? ')
param dailyQuotaGb int?

@description('(Optional) - How long should data retain within the workspace? Defaults to 31 days.')
param retentionInDays int = 31

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: deploymentLocation
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

output workspaceName string = workspace.name
output workspaceId string = workspace.id
