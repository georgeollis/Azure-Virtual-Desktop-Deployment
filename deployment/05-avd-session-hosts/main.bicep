targetScope = 'subscription'

param deploymentLocation string = deployment().location

var sessionHostObject = {
  deploymentLocation: deploymentLocation
  adminPassword: 'burabkdbuasdubsad!s'
  computeGalleryProperties: {
    imageGalleryDefintionName: 'lol'
    imageGalleryName: 'devavdpocuksagc01'
    imageGalleryVersionName: '0.0.1' 
    resourceGroup: 'dev-avd-poc-svcs-rg'
    subscriptionId: subscription().id
  }
}

var resourceGroupObject = {
  name: 'dev-avd-poc-compute-uks-rg'
  location: deploymentLocation
  tags: {
    POC: 'AVD'
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

resource avd_session_host_resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
  tags: resourceGroupObject.tags
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
    hostPoolName: 
    hostPoolResourceGroupName: 
    virtualNetworkProperties: {
      resourceGroupName: 
      subnetName: 
      virtualNetworkName: 
    }
    vmDiskType: 
    vmPrefix: 
    vmSize: 
  }
  scope: avd_session_host_resourceGroup
}
