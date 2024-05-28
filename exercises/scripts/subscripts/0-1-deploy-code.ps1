#!/usr/bin/env pwsh

param(
    [string]$ResourceGroupName,
    [string]$AppServiceName,
    [string]$CodePackagePath = "../../src/web-app.zip"
)

Write-Output "`nDeploying web app code package to app service `"${AppServiceName}`" in resource group `"${ResourceGroupName}`"..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy()
az webapp deploy `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --type zip `
    --src-path ../../src/web-app.zip
