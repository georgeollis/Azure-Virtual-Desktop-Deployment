param(
    [Parameter(Mandatory=$true)]$MANAGED_IMAGE_RESOURCE_GROUP,
    [Parameter(Mandatory=$true)]$ARM_SUBSCRIPTION_ID,
    [Parameter(Mandatory=$true)]$ARM_CLIENT_ID,
    [Parameter(Mandatory=$true)]$ARM_CLIENT_SECRET,
    [Parameter(Mandatory=$true)]$ARM_TENANT_ID
)

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID | Out-Null
az account set -s $ARM_SUBSCRIPTION_ID

$managedImages = az image list --resource-group $MANAGED_IMAGE_RESOURCE_GROUP --subscription $ARM_SUBSCRIPTION_ID --query "reverse(sort_by([].{name:name, id:id}, &name))" | Out-String | ConvertFrom-Json

if ($managedImages) {
    Write-Host "Found $($managedImages.Count) to delete!"
    Write-Host "Cleaning Up AVD Managed Images"
    foreach ($managedImage in $managedImages) {
        Write-Host "Found a match, deleting orphaned managed image: $managedImage"
        az image delete --ids $($managedImage.id) | Out-Null
    }
}
else {
    Write-Host "No images found."
}

