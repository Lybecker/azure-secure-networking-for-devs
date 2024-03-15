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

Write-Output "`nUsing config:`n  - Team name: ${TeamName}`n  - Hub location: ${HubLocation}`n  - EU location: ${EuLocation}`n  - US location: ${UsLocation}"

$Locations = @($HubLocation, $EuLocation, $UsLocation)
$Environment = "dev"
$ResourceGroupNames = @("rg-hub-${TeamName}-${Environment}", "rg-${TeamName}-${Environment}-eu", "rg-${TeamName}-${Environment}-us")
$StorageAccountNames = @("sthub${TeamName}${Environment}", "st${TeamName}${Environment}eu", "st${TeamName}${Environment}us")
$AppServicePlanNamePrefix = "asp-${TeamName}-${Environment}"
$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNames = @("${AppServiceNamePrefix}-eu", "${AppServiceNamePrefix}-us")
$HubVnetName = "vnet-${TeamName}-${Environment}-${HubLocation}"
$JumpboxNsgName = "nsg-jumpbox-${TeamName}-${Environment}"
$JumpboxNicName = "nic-jumpbox-${TeamName}-${Environment}"
$JumpboxVmName = "vm${TeamName}"  # Max 15 characters for Windows machines

# To list available VMs, run command "az vm image list --offer Windows-11 --all --output table"
$JumpboxVmImage = "MicrosoftWindowsDesktop:windows-11:win11-23h2-pro:22631.3007.240105" # URN format for '--image': "Publisher:Offer:Sku:Version"

$JumpboxSubnetName = "snet-shared-${TeamName}-${Environment}-${HubLocation}"
$JumpboxAdminUsername = "jumpboxuser"
$JumpboxAdminPassword = "JumpboxPassword123!"

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

az storage account create `
    --name "sthub${TeamName}${Environment}" `
    --resource-group $ResourceGroupNames[0] `
    --location $HubLocation `
    --kind StorageV2 `
    --sku Standard_LRS

az storage account create `
    --name "st${TeamName}${Environment}eu" `
    --resource-group $ResourceGroupNames[1] `
    --location $EuLocation `
    --kind StorageV2 `
    --sku Standard_LRS

az storage account create `
    --name "st${TeamName}${Environment}us" `
    --resource-group $ResourceGroupNames[2] `
    --location $UsLocation `
    --kind StorageV2 `
    --sku Standard_LRS

Write-Output "`nCreating app service plans..."
# https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create()

$AppServicePlanSku = "S1"

az appservice plan create `
    --name "${AppServicePlanNamePrefix}-eu" `
    --resource-group $ResourceGroupNames[1] `
    --location $EuLocation `
    --sku $AppServicePlanSku `
    --is-linux

az appservice plan create `
    --name "${AppServicePlanNamePrefix}-us" `
    --resource-group $ResourceGroupNames[2] `
    --location $UsLocation `
    --sku $AppServicePlanSku `
    --is-linux

Write-Output "`nCreating web apps..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create()

az webapp create `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupNames[1] `
    --plan "${AppServicePlanNamePrefix}-eu" `
    --runtime PYTHON:3.9

az webapp create `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupNames[2] `
    --plan "${AppServicePlanNamePrefix}-us" `
    --runtime PYTHON:3.9

Write-Output "`nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set()

az webapp config appsettings set `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupNames[1] `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=eu

az webapp config appsettings set `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupNames[2] `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=us

for ($i = 0; $i -lt 2; $i++) {
    $AppServiceName = $AppServiceNames[$i]
    $ResourceGroupName = $ResourceGroupNames[($i + 1)]

    Write-Output "`nAssigning identity for app service `"${AppServiceName}`" (resource group `"${ResourceGroupName}`")..."
    # https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign()

    $AppServicePrincipalId = (az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName | ConvertFrom-Json).principalId
    Write-Output "Principal ID of app service ${AppServiceName}: ${AppServicePrincipalId}"

    Write-Output "`nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
    Start-Sleep -Seconds 15

    for ($j = 0; $j -lt 3; $j++) {
        $StorageAccountName = $StorageAccountNames[$j]
        $ResourceGroupName = $ResourceGroupNames[$j]

        if (($AppServiceName.EndsWith("eu") -and $StorageAccountName.EndsWith("us")) -or ($AppServiceName.EndsWith("us") -and $StorageAccountName.EndsWith("eu"))) {
            Write-Output "`nSkipping role assignment for app service ${AppServiceName} in storage account ${StorageAccountName}"
            continue
        }

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

Write-Output "`nDeploying web app code package..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy()

az webapp deploy `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupNames[1] `
    --type zip `
    --src-path ../../src/web-app.zip

az webapp deploy `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupNames[2] `
    --type zip `
    --src-path ../../src/web-app.zip

# Create VNET and subnet in hub resource group
.\subscripts\1-1-vnet.ps1 $TeamName $HubLocation $ResourceGroupNames[0] "10.0.0"
.\subscripts\2-1-subnet.ps1 $TeamName $HubLocation "rg-hub-${TeamName}-${Environment}" "shared" "10.0.0.0/26" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

Write-Output "`nCreating network security group (NSG) for jumpbox..."
# https://learn.microsoft.com/cli/azure/network/nsg?view=azure-cli-latest#az-network-nsg-create()

az network nsg create `
    --name $JumpboxNsgName `
    --resource-group $ResourceGroupNames[0] `
    --location $HubLocation `
    --no-wait false

Write-Output "`nCreating network interface (NIC) for jumpbox..."
# https://learn.microsoft.com/cli/azure/network/nic?view=azure-cli-latest#az-network-nic-create()

az network nic create `
    --name $JumpboxNicName `
    --resource-group $ResourceGroupNames[0] `
    --location $HubLocation `
    --vnet-name $HubVnetName `
    --subnet $JumpboxSubnetName `
    --network-security-group $JumpboxNsgName

Write-Output "`nCreating jumpbox virtual machine..."
# https://learn.microsoft.com/cli/azure/vm?view=azure-cli-latest#az-vm-create()

az vm create `
    --name $JumpboxVmName `
    --resource-group $ResourceGroupNames[0] `
    --location $HubLocation `
    --image $JumpboxVmImage `
    --admin-username $JumpboxAdminUsername `
    --admin-password $JumpboxAdminPassword `
    --nics $JumpboxNicName
