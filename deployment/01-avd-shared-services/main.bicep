targetScope = 'resourceGroup'

param deploymentLocation string = resourceGroup().location
param tags object = resourceGroup().tags
