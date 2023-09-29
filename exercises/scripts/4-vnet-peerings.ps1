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

$Environment = "dev"

$ResourceGroupNameHub = "rg-hub-${TeamName}-${Environment}"
$ResourceGroupNameEu = "rg-${TeamName}-${Environment}-eu"
$ResourceGroupNameUs = "rg-${TeamName}-${Environment}-us"

$VnetNameEu = "vnet-${TeamName}-${Environment}-${EuLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${UsLocation}"
$VnetNameHub = "vnet-${TeamName}-${Environment}-${HubLocation}"

Write-Output "`nPeering virtual networks to using the hub and spoke model..."

.\subscripts\4-1-vnet-peerings.ps1 -ResourceGroupName1 $ResourceGroupNameHub -VnetName1 $VnetNameHub -ResourceGroupName2 $ResourceGroupNameEu -VnetName2 $VnetNameEu
.\subscripts\4-1-vnet-peerings.ps1 -ResourceGroupName1 $ResourceGroupNameHub -VnetName1 $VnetNameHub -ResourceGroupName2 $ResourceGroupNameUs -VnetName2 $VnetNameUs
