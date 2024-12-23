#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION,
    [string]$JumpboxAdminUsername = "jumpboxuser",
    [string]$JumpboxAdminPassword = "JumpboxPassword123!",
    [switch]$SkipCodeDeployment,
    [switch]$SkipJumpbox
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

Write-Output "`nUsing config:`n  - Team name: ${TeamName}`n  - Hub location: ${HubLocation}`n  - EU location: ${EuLocation}`n  - US location: ${UsLocation}"

$Locations = @($EuLocation, $UsLocation, $HubLocation)
$Environment = "dev"

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation -Environment $Environment

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US, $env:ASNFD_RESOURCE_GROUP_NAME_HUB)
$StorageAccountNames = @($env:ASNFD_STORAGE_ACCOUNT_NAME_EU, $env:ASNFD_STORAGE_ACCOUNT_NAME_US, $env:ASNFD_STORAGE_ACCOUNT_NAME_HUB)
$AppServicePlanNames = @($env:ASNFD_APP_SERVICE_PLAN_NAME_EU, $env:ASNFD_APP_SERVICE_PLAN_NAME_US)
$AppServiceNames = @($env:ASNFD_APP_SERVICE_NAME_EU, $env:ASNFD_APP_SERVICE_NAME_US)

$AzureSubscriptionId = (az account show | ConvertFrom-Json).id

Write-Output "`nAzure subscription ID: ${AzureSubscriptionId}"

for ($i = 0; $i -lt 3; $i++) {
    $ResourceGroupName = $ResourceGroupNames[$i]
    $Location = $Locations[$i]
    Write-Output "`nCreating resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
    az group create --name $ResourceGroupName --location $Location
}

Write-Output "`nCreating storage accounts..."
# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create()

for ($i = 0; $i -lt 3; $i++) {
    az storage account create `
        --name $StorageAccountNames[$i] `
        --resource-group $ResourceGroupNames[$i] `
        --location $Locations[$i] `
        --kind StorageV2 `
        --sku Standard_LRS
}

$AppServicePlanSku = "B1"
Write-Output "`nCreating app service plans with SKU `"${AppServicePlanSku}`" and app services..."

for ($i = 0; $i -lt 2; $i++) {
    $AppServicePlanName = $AppServicePlanNames[$i]
    $AppServiceName = $AppServiceNames[$i]
    $ResourceGroupName = $ResourceGroupNames[$i]
    $Location = $Locations[$i]

    Write-Output "`nCreating app service plan `"${AppServicePlanName}`" in resource group `"${ResourceGroupName}`" in location `"${Location}`"..."
    # https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create()
    az appservice plan create `
        --name $AppServicePlanName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku $AppServicePlanSku `
        --is-linux
}

for ($i = 0; $i -lt 2; $i++) {
    $AppServicePlanName = $AppServicePlanNames[$i]
    $AppServiceName = $AppServiceNames[$i]
    $ResourceGroupName = $ResourceGroupNames[$i]
    $Location = $Locations[$i]

    Write-Output "`nCreating web app service `"${AppServiceName}`" for plan `"${AppServicePlanName}`" in resource group `"${ResourceGroupName}`"..."
    # https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create()
    az webapp create `
        --name $AppServiceNames[$i] `
        --resource-group $ResourceGroupNames[$i] `
        --plan $AppServicePlanNames[$i] `
        --runtime PYTHON:3.9
}

Write-Output "`nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set()

az webapp config appsettings set `
    --name $AppServiceNames[0] `
    --resource-group $ResourceGroupNames[0] `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=eu

az webapp config appsettings set `
    --name $AppServiceNames[1] `
    --resource-group $ResourceGroupNames[1] `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=us

for ($i = 0; $i -lt 2; $i++) {
    $AppServiceName = $AppServiceNames[$i]
    $ResourceGroupName = $ResourceGroupNames[$i]

    Write-Output "`nAssigning identity for app service `"${AppServiceName}`" (resource group `"${ResourceGroupName}`")..."
    # https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign()

    $AppServicePrincipalId = (az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName | ConvertFrom-Json).principalId
    Write-Output "Principal ID of app service `"${AppServiceName}`": ${AppServicePrincipalId}"

    Write-Output "`nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
    Start-Sleep -Seconds 15

    for ($j = 0; $j -lt 3; $j++) {
        $StorageAccountName = $StorageAccountNames[$j]
        $ResourceGroupName = $ResourceGroupNames[$j]

        # commenting the below code, to allow all storage accounts accessible from all app services. helps to validate ASG/NSG exercise.
        
        # if (($AppServiceName.EndsWith("eu") -and $StorageAccountName.EndsWith("us")) -or ($AppServiceName.EndsWith("us") -and $StorageAccountName.EndsWith("eu"))) {
        #     Write-Output "`nSkipping role assignment for app service ${AppServiceName} in storage account ${StorageAccountName}"
        #     continue
        # }

        Write-Output "`nAdding Storage Blob Data Contributor role for app service `"${AppServiceName}`" in storage account `"${StorageAccountName}`"..."
        # https://learn.microsoft.com/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create()

        $Scope = "/subscriptions/${AzureSubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
        Write-Output "Scope: ${Scope}"

        az role assignment create `
            --assignee-object-id $AppServicePrincipalId `
            --assignee-principal-type "ServicePrincipal" `
            --role "Storage Blob Data Contributor" `
            --scope $Scope
    }
}

# Create VNET and subnet in hub resource group
.\subscripts\1-1-vnet.ps1 $env:ASNFD_VNET_NAME_HUB $HubLocation $env:ASNFD_RESOURCE_GROUP_NAME_HUB "10.0.0"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName $env:ASNFD_DEFAULT_SNET_NAME_HUB `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    -AddressPrefixes "10.0.0.0/26" `
    -VnetName $env:ASNFD_VNET_NAME_HUB `
    -AdditionalArguments "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

if ($SkipJumpbox) {
    Write-Output "`nSkipping jumpbox creation"
} else {
    Write-Output "`nCreating jumpbox..."
    .\subscripts\0-2-jumpbox.ps1 `
        -TeamName $TeamName `
        -Environment $Environment `
        -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
        -Location $HubLocation `
        -JumpboxAdminUsername $JumpboxAdminUsername `
        -JumpboxAdminPassword $JumpboxAdminPassword `
        -VnetName $env:ASNFD_VNET_NAME_HUB `
        -SubnetName $env:ASNFD_DEFAULT_SNET_NAME_HUB
}

if ($SkipCodeDeployment) {
    Write-Output "`nSkipping code deployment"
} else {
    .\0-1-code-deployment.ps1 -TeamName $TeamName
}

Write-Output "`nDone"
