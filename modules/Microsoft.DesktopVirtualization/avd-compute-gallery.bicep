targetScope = 'resourceGroup'

@description('The name of the shared image gallery to deploy')
param name string

@description('The location of the resource to deploy.')
param location string = resourceGroup().location

@description('An Azure Compute Gallery storing virtual machine images and VM applications')
param computeGalleryDescription string = 'An Azure Compute Gallery storing virtual machine images and VM applications'

resource sharedImageGallery 'Microsoft.Compute/galleries@2020-09-30' = {
  name: name
  location: location
  properties: {
    description: computeGalleryDescription
  }
}
