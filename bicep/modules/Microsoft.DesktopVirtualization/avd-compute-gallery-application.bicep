targetScope = 'resourceGroup'

type computeGalleryApplicationsType = {
  name: string
  supportedOsType: 'Windows' | 'Linux'
  description: string?
}[]

@description('(Required) - Properties for compute gallery applications.')
param computeGalleryApplicationObject computeGalleryApplicationsType 

@description('(Optional) - The location of the resource being deployed. Defaults to the resource group location')
param deploymentLocation string = resourceGroup().location

@description('(Required) - The name of the Azure Compute Gallery resource this application definition will be created into.')
param computeGalleryName string

resource computeGallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: computeGalleryName
}

resource applications 'Microsoft.Compute/galleries/applications@2022-03-03' =[ for (item, index) in computeGalleryApplicationObject : {
  name: computeGalleryApplicationObject[index].name
  location: deploymentLocation
  parent: computeGallery
  properties: {
    supportedOSType: computeGalleryApplicationObject[index].supportedOsType
    description: computeGalleryApplicationObject[index].?description
  }
}]
