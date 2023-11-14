targetScope = 'subscription'

param deploymentLocation string = deployment().location

var sessionHostObject = {
  
  deploymentLocation: deploymentLocation
  adminPassword: 'burabkdbuasdubsad!s'
  tags: {
    POC: 'AVD'
  }

  computeGalleryProperties: {
    imageGalleryDefintionName: 'lol'
    imageGalleryName: 'devavdpocuksagc01'
    imageGalleryVersionName: '0.0.1' 
    resourceGroup: 'dev-avd-poc-svcs-rg'
    subscriptionId: subscription().id
  }

  hostPoolName: 'dev-avd-poc-uks-hp-01'
  hostPoolResourceGroupName: 'dev-avd-poc-serviceobjects-uks-rg'
  vmDiskType: 'Standard_LRS'
  vmSize: 'Standard_B2Ms'
  instances: 1

  virtualNetworkProperties: {
    resourceGroupName: 'dev-avd-poc-svcs-rg'
    subnetName: 'default'
    virtualNetworkName: 'vm-vnet' 
  }

}
var resourceGroupObject = {
  name: 'dev-avd-poc-compute-uks-rg'
  location: deploymentLocation
  tags: {
    POC: 'AVD'
  }
}

resource avd_session_host_resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
  tags: resourceGroupObject.tags
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' existing = {
  name: sessionHostObject.hostPoolName
  scope: resourceGroup(sessionHostObject.hostPoolResourceGroupName)
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: sessionHostObject.virtualNetworkProperties.virtualNetworkName
  scope: resourceGroup(sessionHostObject.virtualNetworkProperties.resourceGroupName)

  resource subnet 'subnets' existing = {
    name: sessionHostObject.virtualNetworkProperties.subnetName
  }
}

resource computeGallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: sessionHostObject.computeGalleryProperties.imageGalleryName
  scope: resourceGroup(sessionHostObject.computeGalleryProperties.resourceGroup)
  resource images 'images' existing = {
    name: sessionHostObject.computeGalleryProperties.imageGalleryVersionName
    resource versions 'versions@2022-03-03' existing = {
      name: sessionHostObject.computeGalleryProperties.imageGalleryVersionName
    }
  }
}

module avd_session_host '../../modules/Microsoft.DesktopVirtualization/avd-session-host.bicep' = {
  name: 'avd-session-hosts'
  params: {
    deploymentLocation: sessionHostObject.deploymentLocation
    adminPassword: sessionHostObject.adminPassword
    computeGalleryProperties: {
      imageGalleryDefintionName: computeGallery::images.name
      imageGalleryName: computeGallery.name
      imageGalleryVersionName: computeGallery::images::versions.name
      resourceGroup: sessionHostObject.computeGalleryProperties.resourceGroup
      subscriptionId: sessionHostObject.computeGalleryProperties.subscriptionId
    }
    hostPoolName: hostPool.name
    hostPoolResourceGroupName: sessionHostObject.hostPoolResourceGroupName
    virtualNetworkProperties: {
      resourceGroupName: sessionHostObject.virtualNetworkProperties.resourceGroupName
      subnetName: virtualNetwork::subnet.name
      virtualNetworkName: virtualNetwork.name
    }
    vmDiskType: sessionHostObject.vmDiskType
    vmSize: sessionHostObject.vmSize
    tags: sessionHostObject.tags
    instances: sessionHostObject.instances
  }
  scope: avd_session_host_resourceGroup
}

