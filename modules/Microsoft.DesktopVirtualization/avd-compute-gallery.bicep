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

@description('Properties for the Azure Compute Gallery')
param computeGalleryObject computeGalleryType = {
  name: 'computegallis01'
}

type computeGalleryApplicationsType = {
  name: string
  supportedOsType: 'Windows' | 'Linux'
  description: string?
}[]


@description('Properties for the image definition.')
param imageDefinitionObject imageDefinitionType = [
  {
    name: 'windows-vm'
    architecture: 'x64'
    hyperVGeneration: 'V2'
    identifier: {
      offer: 'Gollis'
      publisher: 'Gollis'
      sku: 'Gollis'
    }
    osState: 'Generalized'
    osType: 'Windows'
  }
]

@description('Properties for compute gallery applications.')
param computeGalleryApplicationObject computeGalleryApplicationsType = [
   {
    name: 'Google-Chrone'
    supportedOsType: 'Windows'
   }
   {
    name: 'Notepad'
    supportedOsType: 'Windows'
   }
]

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

resource image 'Microsoft.Compute/galleries/images@2022-03-03' = [ for (item, index) in imageDefinitionObject : if (deployImageDefinition) {
  name: imageDefinitionObject[index].name
  location: deploymentLocation
  parent: computeGallery
  properties: {
    architecture: imageDefinitionObject[index].architecture
    description: imageDefinitionObject[index].?description
    endOfLifeDate: imageDefinitionObject[index].?endOfLifeDate
    eula: imageDefinitionObject[index].?eula
    hyperVGeneration: imageDefinitionObject[index].hyperVGeneration
    identifier: {
      offer: imageDefinitionObject[index].identifier.offer
      publisher: imageDefinitionObject[index].identifier.publisher
      sku: imageDefinitionObject[index].identifier.sku
    }
    osState: imageDefinitionObject[index].osState
    osType: imageDefinitionObject[index].osType
  }
}]

resource applications 'Microsoft.Compute/galleries/applications@2022-03-03' =[ for (item, index) in computeGalleryApplicationObject : if(deployApplicationDefinition) {
  name: computeGalleryApplicationObject[index].name
  location: deploymentLocation
  parent: computeGallery
  properties: {
    supportedOSType: computeGalleryApplicationObject[index].supportedOsType
    description: computeGalleryApplicationObject[index].?description
  }
}]
