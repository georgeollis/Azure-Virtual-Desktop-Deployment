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

param computeGalleryName string

param imageDefinitionObject imageDefinitionType

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
