#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $env:EU_LOCATION -UsLocation $env:US_LOCATION -HubLocation $HubLocation -Environment "dev"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName "AzureFirewallSubnet" `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    -AddressPrefixes "10.0.0.128/26" `
    -VnetName $env:ASNFD_VNET_NAME_HUB

.\subscripts\5-1-firewall.ps1 `
    -TeamName $TeamName `
    -Location $HubLocation `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    -VnetName $env:ASNFD_VNET_NAME_HUB

# TODO: Routing
