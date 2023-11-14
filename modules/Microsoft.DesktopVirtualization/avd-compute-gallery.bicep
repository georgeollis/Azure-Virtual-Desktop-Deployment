targetScope = 'resourceGroup'

type computeGalleryType = {
  @description('The name of the shared image gallery to deploy')
  name: string
  @description('An Azure Compute Gallery storing virtual machine images and VM applications')
  description: string?
}

type imageDefinitionType = {
  name: string
  identifier: {
    offer: string
    publisher: string
    sku: string
  }
  hyperVGeneration: 'V1' | 'V2'
  architecture: 'Arm64' | 'x64'
  description: string?
  endOfLifeDate: string?
  eula: string?
  osState: 'Generalized' | 'Specialized'
  osType: 'Windows' | 'Linux'

}[]

type computeGalleryApplicationsType = {
  name: string
  supportedOsType: 'Windows' | 'Linux'
  description: string?
}[]

@description('Properties for the Azure Compute Gallery')
param computeGalleryObject computeGalleryType

@description('Properties for the image definition.')
param imageDefinitionObject imageDefinitionType

@description('Properties for compute gallery applications.')
param computeGalleryApplicationObject computeGalleryApplicationsType

param deploymentLocation string = resourceGroup().location

param deployImageDefinition bool = true

param deployApplicationDefinition bool = true

resource computeGallery 'Microsoft.Compute/galleries@2020-09-30' = {
  name: computeGalleryObject.name
  location: deploymentLocation
  properties: {
    description: computeGalleryObject.?description
  }
}

module imageDefinition 'avd-compute-gallery-image.bicep' = if (deployImageDefinition) {
  name: 'avd-deployment-image-defintion'
  params: {
    computeGalleryName: computeGallery.name
    deploymentLocation: computeGallery.location
    imageDefinitionObject: imageDefinitionObject
  }
}

module applicationDefinition 'avd-compute-gallery-application.bicep' = if (deployApplicationDefinition) {
  name: 'avd-deployment-application-definition'
  params: {
    computeGalleryName: computeGallery.name
    computeGalleryApplicationObject: computeGalleryApplicationObject
    deploymentLocation: computeGallery.location
  }
}
