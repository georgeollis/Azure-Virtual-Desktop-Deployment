targetScope = 'resourceGroup'

type domainJoinType = {
  @description('OU Path where new AVD Session Hosts will be placed in Active Directory')
  ouPath: string
  @description('The userPrincipalName of the user account that should be used to join virtual machines to the domain.')
  userPrincipalName: string
  @secure()
  password: string
  @description('The name of the domain to domain, for example, domain.co.uk')
  domainName: string
}

type virtualNetworkType = {
  @description('Resource group location of the virtual network')
  resourceGroupName: string
  @description('Virtual network name')
  virtualNetworkName: string
  @description('Subnet to place AVD session hosts into')
  subnetName: string
}

type computeGalleryType = {
  @description('Subscription containing the Shared Image Gallery')
  subscriptionId: string
  @description('Resource Group containing the Shared Image Gallery.')
  resourceGroup: string
  @description('Name of the existing Shared Image Gallery to be used for image.')
  imageGalleryName: string
  @description('Name of the Shared Image Gallery Definition being used for deployment. I.e: AVDGolden')
  imageGalleryDefintionName: string
  @description('Version name for image to be deployed as. I.e: 1.0.0')
  imageGalleryVersionName: string
}

@description('Compute image gallery properties.')
param computeGalleryProperties computeGalleryType

@description('Virtual network properies.')
param virtualNetworkProperties virtualNetworkType

@description('Domain join properties. Required if enableDomainJoin is true')
param domainJoinProperties domainJoinType?

@description('Join session hosts to domain?')
param enableDomainJoin bool = false

@description('(Optional) - Should the Azure Monitor Agent (AMA) be installed?')
param enableAMA bool = false

@description('(Optional) - Should session hosts be added to Microsoft Entra ID?')
param enableEntraJoin bool = false

@description('(Optional) - Should session hosts be assosicated with a data collection rule?')
param enableDcr bool = false

param dataCollectionRuleId string?

@description('How many session hosts should be deployed?')
param instances int = 1

@description('How many sessions hosts are already deployed?')
param currentInstances int = 0

@description('The name of the hostPool resource session hosts should join.')
param hostPoolName string

@description('Location for all standard resources to be deployed into.')
param deploymentLocation string = resourceGroup().location

param vmPrefix string

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string

@description('What is the selected size for the virtual machine?')
param vmSize string

@description('Tags metadata for resources')
param tags object?

@description('Do you want to enable ephereralDisks for session hosts?')
param ephemeralDisk bool = false

@description('Name of the local administrator')
param adminUsername string = 'avdadmin'

@description('The password for the local administrator')
@secure()
param adminPassword string

param baseTime string = utcNow('u')

var expirationTime = dateTimeAdd(baseTime, 'PT48H')

// Get the hostPool Resource
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' existing = {
  name: hostPoolName
}

// Simply getting a token. Does not delete or modify hostPool in anyway.
resource hostPoolRegistration 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = { 
  name: hostPool.name
  properties: {
    hostPoolType: hostPool.properties.hostPoolType
    loadBalancerType:  hostPool.properties.loadBalancerType
    preferredAppGroupType: hostPool.properties.preferredAppGroupType
    registrationInfo: {
      expirationTime: expirationTime
      token: null
      registrationTokenOperation: 'Update'
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkProperties.virtualNetworkName
  scope: resourceGroup(virtualNetworkProperties.resourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: virtualNetworkProperties.subnetName
  parent: virtualNetwork
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, instances): {
  name: '${vmPrefix}-${i + currentInstances}-nic'
  location: deploymentLocation
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, instances): {
  name: '${vmPrefix}-${i + currentInstances}'
  location: deploymentLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmPrefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
    }
    storageProfile: {
      osDisk: {
        name: '${vmPrefix}-${i}-os'
        managedDisk: {
          storageAccountType: ephemeralDisk ? 'Standard_LRS' : vmDiskType
        }
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadOnly'
        diffDiskSettings: ephemeralDisk ? {
          option: 'Local'
          placement: 'CacheDisk'
        } : null
      }
      imageReference: {
        id: '/subscriptions/${computeGalleryProperties.subscriptionId}/resourceGroups/${computeGalleryProperties.resourceGroup}/providers/Microsoft.Compute/galleries/${computeGalleryProperties.imageGalleryName}/images/${computeGalleryProperties.imageGalleryDefintionName}/versions/${computeGalleryProperties.imageGalleryVersionName}'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmPrefix}-${i}-nic')
        }
      ]
    }
  }
  tags: tags
  dependsOn: [
    nic[i]
  ]
}]

resource sessionHostDomainJoin 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, instances): if (enableDomainJoin) {
  name: '${vmPrefix}-${i + currentInstances}/joindomain'
  location: deploymentLocation
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainJoinProperties.?domainName
      ouPath: domainJoinProperties.?ouPath
      user: domainJoinProperties.?userPrincipalName
      restart: 'true'
      options: '3'
      NumberOfRetries: '4'
      RetryIntervalInMilliseconds: '30000'
    }
    protectedSettings: {
      password: domainJoinProperties.?password
    }
  }

  dependsOn: [
    vm[i]
  ]
}]

resource sessionHostAzureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, instances): if (enableAMA) {
  name: '${vmPrefix}-${i + currentInstances}/ama-agent'
  location: deploymentLocation
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
  }

  dependsOn: [
    vm[i]
  ]
}]

resource sessionHostEntraJoin 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = [for i in range(0, instances): if (enableEntraJoin) {
  name: '${vmPrefix}-${i + currentInstances}/entraJoin'
  location: deploymentLocation
  properties:{
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  } 
}]

resource sessionHostAVDAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, instances): {
  name: '${vmPrefix}-${i + currentInstances}/dscextension'
  location: deploymentLocation
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPool.name
        registrationInfoToken: hostPoolRegistration.properties.registrationInfo.token
      }
    }
  }
  dependsOn: [
    vm[i]
    sessionHostDomainJoin[i]
  ]
}]

resource sessionHostDCRA 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' =  [ for (item, i) in range(0, instances) : if (enableDcr) {
  name: '${vmPrefix}-${i + currentInstances}-dcra'
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
  }
}]
