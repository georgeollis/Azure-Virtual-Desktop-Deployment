targetScope = 'subscription'

param deploymentLocation string = deployment().location

var computeGalleryObjects = [ {
  computeGalleryObject: {
    name: 'dev-avdpoc-uks-agc-01'
  }
}]

var resourceGroupObject = {
  name: 'dev-avd-poc-svcs-rg'
  location: deploymentLocation
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
}

module avd_shared_services '../../modules/Microsoft.DesktopVirtualization/avd-compute-gallery.bicep' = [for (item, index) in computeGalleryObjects: {
  name: 'avd-shared-services-${index}'
  params: {
    computeGalleryObject: {
      name: item.computeGalleryObject.name
    }
    deploymentLocation: deploymentLocation
    tags: resourceGroup.tags
  }
  scope: resourceGroup
}]


output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output deploymentLocation string = deploymentLocation

output avd_shared_services array = [for (item, index) in computeGalleryObjects: {
  computeGalleryName: avd_shared_services[index].outputs.computeGalleryName
  computeGalleryId: avd_shared_services[index].outputs.computeGalleryId
} ]
