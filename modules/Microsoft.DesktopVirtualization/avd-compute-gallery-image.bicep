targetScope = 'resourceGroup'

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

@description('(Required) - The name of the Azure Compute Gallery resource this image definition will be created into.')
param computeGalleryName string

@description('(Required) - The image definition being created within the Azure Compute Gallery.')
param imageDefinitionObject imageDefinitionType

@description('(Optional) - The location of the resource being deployed. Defaults to the resource group location')
param deploymentLocation string = resourceGroup().location

resource computeGallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: computeGalleryName
}

resource image 'Microsoft.Compute/galleries/images@2022-03-03' = [ for (item, index) in imageDefinitionObject : {
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
