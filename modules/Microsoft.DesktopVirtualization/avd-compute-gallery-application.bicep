targetScope = 'resourceGroup'

type computeGalleryApplicationsType = {
  name: string
  supportedOsType: 'Windows' | 'Linux'
  description: string?
}[]

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
