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

.\subscripts\2-1-subnet.ps1 $TeamName $HubLocation "rg-hub-${TeamName}-${Environment}" "shared" "10.0.0.0/26" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

.\subscripts\2-1-subnet.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "shared" "10.0.4.0/25" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"
.\subscripts\2-1-subnet.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "apps" "10.0.4.128/25" "--delegations Microsoft.Web/serverFarms"

.\subscripts\2-1-subnet.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "shared" "10.0.8.0/25" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"
.\subscripts\2-1-subnet.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "apps" "10.0.8.128/25" "--delegations Microsoft.Web/serverFarms"

.\subscripts\2-2-private-dns-zones.ps1 $TeamName

.\subscripts\2-3-private-endpoints.ps1 $TeamName $EuLocation $UsLocation $HubLocation

Write-Output "`nDisabling public access to storage accounts..."
.\subscripts\2-3-2-storage-accounts-disable-public-access.ps1 -TeamName $TeamName

.\subscripts\2-4-web-app-vnet-integration.ps1 $TeamName $EuLocation $UsLocation $HubLocation
