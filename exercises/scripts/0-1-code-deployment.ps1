#!/usr/bin/env pwsh

param([string]$TeamName = $env:TEAM_NAME)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

.\set-resource-names.ps1 -TeamName $TeamName -Environment "dev"

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US)
$AppServiceNames = @($env:ASNFD_APP_SERVICE_NAME_EU, $env:ASNFD_APP_SERVICE_NAME_US)

for ($i = 0; $i -lt 2; $i++) {
    $ResourceGroupName = $ResourceGroupNames[$i]
    $AppServiceName = $AppServiceNames[$i]

    Write-Output "Deploying code to app service `"$AppServiceName`" in resource group `"$ResourceGroupName`"..."

    .\subscripts\0-1-deploy-code.ps1 `
        -ResourceGroupName $ResourceGroupName `
        -AppServiceName $AppServiceName `
        -CodePackagePath "../../src/web-app.zip"
}
