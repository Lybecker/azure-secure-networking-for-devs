#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$Environment = "dev"

$ResourceGroupNameHub = "rg-hub-${TeamName}-${Environment}"

.\subscripts\2-1-subnet.ps1 $TeamName $HubLocation $ResourceGroupNameHub "firewall" "10.0.0.128/26"

.\subscripts\5-1-firewall.ps1 -TeamName $TeamName -Location $HubLocation

# TODO: Routing
