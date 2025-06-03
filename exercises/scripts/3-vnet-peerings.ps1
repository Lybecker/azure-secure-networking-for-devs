#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $env:EU_LOCATION -UsLocation $env:US_LOCATION -HubLocation $env:HUB_LOCATION -Environment "dev"

$ResourceGroupNameHub = $env:ASNFD_RESOURCE_GROUP_NAME_HUB
$VnetNameHub = $env:ASNFD_VNET_NAME_HUB
$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US)
$VnetNames = @($env:ASNFD_VNET_NAME_EU, $env:ASNFD_VNET_NAME_US)

Write-Output "`nPeering virtual networks to using the hub and spoke model..."

for ($i = 0; $i -lt 2; $i++) {
    .\subscripts\3-1-vnet-peerings.ps1 `
        -ResourceGroupName1 $ResourceGroupNameHub `
        -VnetName1 $VnetNameHub `
        -ResourceGroupName2 $ResourceGroupNames[$i] `
        -VnetName2 $VnetNames[$i]
}


# To validate ASGs and NSGs this is needed.

.\subscripts\3-1-vnet-peerings.ps1 `
        -ResourceGroupName1 $env:ASNFD_RESOURCE_GROUP_NAME_EU `
        -VnetName1 $env:ASNFD_VNET_NAME_EU `
        -ResourceGroupName2 $env:ASNFD_RESOURCE_GROUP_NAME_US `
        -VnetName2 $env:ASNFD_VNET_NAME_US