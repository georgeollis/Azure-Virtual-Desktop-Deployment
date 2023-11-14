param(
    [Parameter(Mandatory = $true)]$MANAGED_IMAGE_RESOURCE_GROUP,
    [Parameter(Mandatory = $true)]$ARM_SUBSCRIPTION_ID,
    [Parameter(Mandatory = $true)]$ARM_CLIENT_ID,
    [Parameter(Mandatory = $true)]$ARM_CLIENT_SECRET,
    [Parameter(Mandatory = $true)]$ARM_TENANT_ID,
    [Parameter()]$VERSIONS_KEEP = 5,
    [Parameter(Mandatory = $true)]$AZURE_COMPUTE_GALLERY_NAME,
    [Parameter(Mandatory = $true)]$AZURE_COMPUTE_GALLERY_IMAGE_NAME
)

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID | Out-Null
az account set -s $ARM_SUBSCRIPTION_ID

$imageVersions = az sig image-version list `
    --gallery-name $AZURE_COMPUTE_GALLERY_NAME `
    --resource-group $MANAGED_IMAGE_RESOURCE_GROUP `
    --gallery-image-name $AZURE_COMPUTE_GALLERY_IMAGE_NAME `
    --query "reverse(sort_by([].{name:name, date:publishingProfile.publishedDate}, &date))" `
| Out-String | ConvertFrom-Json | Sort-Object -Property Date -Descending | Select-Object -Skip $VERSIONS_KEEP

if ($imageVersions) {
    $imageVersions.ForEach({
            Write-Host "Found a match, deleting old image version: $($_.name) with Date: $($_.date)"
            az sig image-version delete `
                --gallery-image-name $AZURE_COMPUTE_GALLERY_IMAGE_NAME `
                --gallery-image-version $($_.name) `
                --gallery-name $AZURE_COMPUTE_GALLERY_NAME `
                --resource-group $MANAGED_IMAGE_RESOURCE_GROUP

        })
} else {
    Write-Host "No images in the Azure Compute Gallery to delete."
}