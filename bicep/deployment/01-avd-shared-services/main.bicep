targetScope = 'subscription'

param deploymentLocation string = deployment().location

var computeGalleryObjects = [ {
  computeGalleryObject: {
    name: 'devavdpocuksagc01'
    deployImageDefinition: true
    imageDefinitionObject: [
      {
        name:  'AVD-Golden-Image'
        architecture: 'x64'
        hyperVGeneration: 'V2'
        identifier: {
          offer: 'AVD-Master-Image'
          publisher: 'Gollis'
          sku: 'AVD'
        }
        osState: 'Generalized'
        osType: 'Windows'
      }
    ]
  }
}]

var resourceGroupObject = {
  name: 'dev-avd-poc-shared-services-rg'
  location: deploymentLocation
  tags: {
    POC: 'AVD'
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupObject.name
  location: resourceGroupObject.location
  tags: resourceGroupObject.tags
}

module avd_shared_services '../../modules/avd-compute-gallery.bicep' = [for (item, index) in computeGalleryObjects: {
  name: 'avd-shared-services-${index}'
  params: {
    computeGalleryObject: {
      name: item.computeGalleryObject.name
    }
    deploymentLocation: deploymentLocation
    tags: resourceGroup.tags
    deployImageDefinition: item.computeGalleryObject.deployImageDefinition
    imageDefinitionObject: item.computeGalleryObject.imageDefinitionObject
    
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
