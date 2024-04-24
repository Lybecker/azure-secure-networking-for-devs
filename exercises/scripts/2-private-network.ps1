#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation -Environment "dev"

# Subnet already created in hub location

.\subscripts\2-1-subnet.ps1 `
    -SubnetName $env:ASNFD_DEFAULT_SNET_NAME_EU `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_EU `
    -AddressPrefixes "10.0.4.0/25" `
    -VnetName $env:ASNFD_VNET_NAME_EU `
    -AdditionalArguments "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName $env:ASNFD_APPS_SNET_NAME_EU `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_EU `
    -AddressPrefixes "10.0.4.128/25" `
    -VnetName $env:ASNFD_VNET_NAME_EU `
    -AdditionalArguments "--delegations Microsoft.Web/serverFarms"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName $env:ASNFD_DEFAULT_SNET_NAME_US `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_US `
    -AddressPrefixes "10.0.8.0/25" `
    -VnetName $env:ASNFD_VNET_NAME_US `
    -AdditionalArguments "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName $env:ASNFD_APPS_SNET_NAME_US `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_US `
    -AddressPrefixes "10.0.8.128/25" `
    -VnetName $env:ASNFD_VNET_NAME_US `
    -AdditionalArguments "--delegations Microsoft.Web/serverFarms"

.\subscripts\2-2-private-dns-zones.ps1 $TeamName

.\subscripts\2-3-private-endpoints.ps1 $TeamName $EuLocation $UsLocation $HubLocation

Write-Output "`nDisabling public access to storage accounts..."
.\subscripts\2-3-2-storage-accounts-disable-public-access.ps1 -TeamName $TeamName

.\subscripts\2-4-web-app-vnet-integration.ps1 $TeamName
