targetScope = 'subscription'

param deploymentLocation string = deployment().location

var sessionHostObject = {

  deploymentLocation: deploymentLocation
  adminPassword: 'Dragon13243s13e1!'
  tags: {
    POC: 'AVD'
  }

  computeGalleryProperties: {
    imageGalleryDefintionName: 'lol'
    imageGalleryName: 'devavdpocuksagc01'
    imageGalleryVersionName: '0.0.1' 
    resourceGroup: 'dev-avd-poc-svcs-rg'
  }

  hostPoolName: 'dev-avd-poc-uks-hp-01'
  hostPoolResourceGroupName: 'dev-avd-poc-serviceobjects-uks-rg'
  vmDiskType: 'Standard_LRS'
  vmSize: 'Standard_B2Ms'
  instances: 1
  currentInstances: 1
  enableEntraJoin: true


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

module avd_session_host '../../modules/Microsoft.DesktopVirtualization/avd-session-host.bicep' = {
  name: 'avd-session-hosts'
  params: {
    deploymentLocation: sessionHostObject.deploymentLocation
    adminPassword: sessionHostObject.adminPassword
    computeGalleryProperties: {
      imageGalleryDefintionName: sessionHostObject.computeGalleryProperties.imageGalleryDefintionName
      imageGalleryName: sessionHostObject.computeGalleryProperties.imageGalleryName
      imageGalleryVersionName: sessionHostObject.computeGalleryProperties.imageGalleryVersionName
      resourceGroup: sessionHostObject.computeGalleryProperties.resourceGroup
    }
    hostPoolName: sessionHostObject.hostPoolName
    hostPoolResourceGroupName: sessionHostObject.hostPoolResourceGroupName
    virtualNetworkProperties: {
      resourceGroupName: sessionHostObject.virtualNetworkProperties.resourceGroupName
      subnetName: sessionHostObject.virtualNetworkProperties.subnetName
      virtualNetworkName: sessionHostObject.virtualNetworkProperties.virtualNetworkName
    }
    vmDiskType: sessionHostObject.vmDiskType
    enableEntraJoin: sessionHostObject.enableEntraJoin
    vmSize: sessionHostObject.vmSize
    tags: sessionHostObject.tags
    instances: sessionHostObject.instances
  } 
  scope: avd_session_host_resourceGroup
}

output sessionHostNames array = avd_session_host.outputs.sessionHosts
