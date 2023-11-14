targetScope = 'resourceGroup'

param deploymentLocation string = resourceGroup().location
param tags object = resourceGroup().tags

var computeGalleryObjects = [ {
  computeGalleryObject: {
    name: 'dev-avdpoc-uks-agc-01'
  }
  deploymentLocation: deploymentLocation
}]

module avd_shared_services '../../modules/Microsoft.DesktopVirtualization/avd-compute-gallery.bicep' = [for (item, index) in computeGalleryObjects: {
  name: 'avd-shared-services-${index}'
  params: {
    computeGalleryObject: {
      name: item.computeGalleryObject.name
    }
    deploymentLocation: item.deploymentLocation
    tags: tags
  }
}]
