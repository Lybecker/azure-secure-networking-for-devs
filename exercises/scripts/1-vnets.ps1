#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

# Virtual network and subnet already created in hub location
.\subscripts\1-1-vnet.ps1 -VnetName $env:ASNFD_VNET_NAME_EU -Location $EuLocation -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_EU -IpPrefix "10.0.4"
.\subscripts\1-1-vnet.ps1 -VnetName $env:ASNFD_VNET_NAME_US -Location $UsLocation -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_US -IpPrefix "10.0.8"
