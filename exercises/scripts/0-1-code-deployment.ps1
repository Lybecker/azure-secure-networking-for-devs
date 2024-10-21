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

if ($EuLocation.Length -eq 0) {
    Write-Error "Invalid argument: EU location missing"
    exit 1
}

if ($UsLocation.Length -eq 0) {
    Write-Error "Invalid argument: US location missing"
    exit 1
}

if ($HubLocation.Length -eq 0) {
    Write-Error "Invalid argument: Hub location missing"
    exit 1
}

Write-Output "`nUsing config:`n  - Team name: ${TeamName}`n  - EU location: ${EuLocation}`n  - US location: ${UsLocation}"

$Environment = "dev"

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation -Environment $Environment

$AppServiceNames = @($env:ASNFD_APP_SERVICE_NAME_EU, $env:ASNFD_APP_SERVICE_NAME_US)

for ($i = 0; $i -lt 2; $i++) {
    Write-Output "Deploying code to app service `"$AppServiceNames[$i]`" in resource group `"$ResourceGroupNames[$i]`"..."

    .\subscripts\0-1-deploy-code.ps1 `
        -ResourceGroupName $ResourceGroupNames[$i] `
        -AppServiceName $AppServiceNames[$i] `
        -CodePackagePath "../../src/web-app.zip"
}
