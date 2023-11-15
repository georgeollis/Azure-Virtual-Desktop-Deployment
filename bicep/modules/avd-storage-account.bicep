targetScope = 'resourceGroup'

type fileSharesType = {
  shareName: string
  shareQuota: int
}[]

param fileShares fileSharesType

param delpoymentLocation string = resourceGroup().location

@description('(Required) - The name of the storage account.')
param name string

@allowed([ 'Premium_LRS', 'Premium_ZRS' ])
@description('(Optional) - The sku of the storage account. Defaults to LRS.')
param sku string = 'Premium_LRS'

param tags object?

//// Azure Files Storage Account for FsLogix Profiles

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  tags: tags
  location: delpoymentLocation
  sku: {
    name: sku
  }
  kind: 'FileStorage'

  properties: {
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
    }
  }

  resource fileServices 'fileServices' = {
    name: 'default'
    properties: {
      protocolSettings: {
        smb: {
          multichannel: {
            enabled: true
          }
        }
      }
    }

    resource shares 'shares' =  [for (share, index) in fileShares: if (!empty(fileShares)) {
      name: toLower(share.shareName)
      properties: {
        enabledProtocols: 'SMB'
        shareQuota: share.shareQuota
      }
    }]
    

  }
}



output id string = storageAccount.id
output name string = storageAccount.name
output location string = storageAccount.location
