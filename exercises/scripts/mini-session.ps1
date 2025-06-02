#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$Location = "swedencentral",
    [switch]$SkipCodeDeployment
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$AppServicePlanSku = "B1"

$Environment = "dev"

$ResourceGroupName = "rg-${TeamName}-${Environment}"
$AppServicePlanName = "asp-${TeamName}-${Environment}"
$AppServiceName = "app-${TeamName}-${Environment}"
$StorageAccountName = "st${TeamName}${Environment}"

Write-Output "`nUsing config:`n  - Team name: ${TeamName}`n  - Location: ${Location}`n  - Resource group: ${ResourceGroupName}`n  - App service plan name: ${AppServicePlanName}`n  - Web app name: ${AppServiceName}`n  - Storage account name: ${StorageAccountName}"

$AzureSubscriptionId = (az account show | ConvertFrom-Json).id
Write-Output "`nAzure subscription ID: ${AzureSubscriptionId}"

Write-Output "`nCreating resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
az group create --name $ResourceGroupName --location $Location

Write-Output "`nCreating storage account `"${StorageAccountName}`" in resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create()
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --kind StorageV2 `
    --sku Standard_LRS

Write-Output "`nCreating app service plan `"${AppServicePlanName}`" in resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
# https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create()
az appservice plan create `
    --name $AppServicePlanName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku $AppServicePlanSku `
    --is-linux

Write-Output "`nCreating web app service `"${AppServiceName}`" for plan `"${AppServicePlanName}`" in resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create()
az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlanName `
    --runtime PYTHON:3.12

Write-Output "`nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set()
az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName

Write-Output "`nAssigning identity for app service `"${AppServiceName}`"..."
# https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign()
$AppServicePrincipalId = (az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName | ConvertFrom-Json).principalId
Write-Output "Principal ID of app service `"${AppServiceName}`": ${AppServicePrincipalId}"

Write-Output "`nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
Start-Sleep -Seconds 15

Write-Output "`nAdding Storage Blob Data Contributor role for app service `"${AppServiceName}`" in storage account `"${StorageAccountName}`"..."
# https://learn.microsoft.com/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create()

$Scope = "/subscriptions/${AzureSubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
Write-Output "Scope: ${Scope}"

az role assignment create `
    --assignee-object-id $AppServicePrincipalId `
    --assignee-principal-type "ServicePrincipal" `
    --role "Storage Blob Data Contributor" `
    --scope $Scope

if ($SkipCodeDeployment) {
    Write-Output "`nSkipping code deployment"
} else {
    Write-Output "`nDeploying web app code package to app service `"${AppServiceName}`" in resource group `"${ResourceGroupName}`"..."
    # https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy()
    az webapp deploy `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --type zip `
        --src-path ../../src/web-app-single-storage.zip
}

Write-Output "Done"
