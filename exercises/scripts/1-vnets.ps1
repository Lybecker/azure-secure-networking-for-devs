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

.\subscripts\1-1-vnet.ps1 $TeamName $HubLocation "rg-hub-${TeamName}-${Environment}" "10.0.0"
.\subscripts\1-1-vnet.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "10.0.4"
.\subscripts\1-1-vnet.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "10.0.8"
