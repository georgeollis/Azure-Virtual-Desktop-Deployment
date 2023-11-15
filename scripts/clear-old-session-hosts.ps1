[CmdletBinding()]
param (
    [Parameter()][string]$HOST_POOL_NAME,
    [Parameter()][string]$HOST_POOL_RESOURCE_GROUP_NAME,
    [Parameter()][string]$ARM_CLIENT_ID,
    [Parameter()][string]$ARM_CLIENT_SECRET,
    [Parameter()][string]$ARM_TENANT_ID,
    [Parameter()][string]$ARM_SUBSCRIPTION_ID
)

Write-Output $HOST_POOL_NAME
Write-Output $HOST_POOL_RESOURCE_GROUP_NAME

Install-Module Az.Accounts -Force
Install-Module Az.DesktopVirtualization -Force

$password = ConvertTo-SecureString $ARM_CLIENT_SECRET -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($ARM_CLIENT_ID, $password)
Connect-AzAccount -ServicePrincipal -Credential $credentials -TenantId $ARM_TENANT_ID -SubscriptionId $ARM_SUBSCRIPTION_ID
 
$sessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $HOST_POOL_RESOURCE_GROUP_NAME `
    -HostPoolName $HOST_POOL_NAME | Select-Object name, @{name = "status"; e = { $_.Status } }, @{name = "hostPoolName"; e = { $($_.Name).Split("/")[0] } }, @{name = "sessionHost"; e = { $($_.Name).Split("/")[1] } }
    
$sessionHosts = $sessionHosts | Where-Object { $_.status -eq "Unavailable" }

$userSessions = Get-AzWvdUserSession -HostPoolName $HOST_POOL_NAME -ResourceGroupName $HOST_POOL_RESOURCE_GROUP_NAME | 
Select-Object @{name = "hostPoolName"; e = { $($_.Name).split("/")[0] } }, @{name = "sessionHost"; e = { $($_.Name).split("/")[1] } }, @{name = "Id"; e = { $($_.Name).split("/")[2] } }

if ($userSessions) {

    foreach ($user in $userSessions) {
      
        if ($user.sessionHost -in $sessionHosts.sessionHost) {
            Remove-AzWvdUserSession `
                -HostPoolName $HOST_POOL_NAME `
                -ResourceGroupName $HOST_POOL_RESOURCE_GROUP_NAME `
                -Id $user.Id `
                -SessionHostName $user.sessionHost `
                -Force

            Write-Output "Clearing session $userId on session host $sessionHostName"
        }
    }
}

Write-Output $sessions

if ($sessionHosts) {
    $sessionHosts | foreach-object {
        
        Write-Host "Removing $($_.sessionHost) from hostpool"
        Remove-AzWvdSessionHost -HostPoolName $HOST_POOL_NAME -Name $_.sessionHost -ResourceGroupName $HOST_POOL_RESOURCE_GROUP_NAME }
}