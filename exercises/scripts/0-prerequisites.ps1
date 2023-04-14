param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "northeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
#$VmName = "vm${TeamName}"
#$VmImage = "MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:22621.1265.230207" # URN format for '--image': "Publisher:Offer:Sku:Version"
#$VmAdminUsername = $TeamName
#$VmAdminPassword = "${TeamName}Password123!"
$StorageAccountNames = @("st${TeamName}${Environment}eu", "st${TeamName}${Environment}us", "stshared${TeamName}${Environment}")
$AppServicePlanNamePrefix = "plan-${TeamName}-${Environment}"
$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNames = @("${AppServiceNamePrefix}-eu", "${AppServiceNamePrefix}-us")

$AzureSubscriptionId = (az account show | ConvertFrom-Json).id

Write-Output "`nAzure subscription ID: ${AzureSubscriptionId}"

Write-Output "`nCreating resource group ${ResourceGroupName}..."

az group create --name $ResourceGroupName --location $PrimaryLocation

Write-Output "`nCreating storage accounts..."
# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create

az storage account create `
    --name "st${TeamName}${Environment}eu" `
    --resource-group $ResourceGroupName `
    --location $PrimaryLocation `
    --kind StorageV2 `
    --sku Standard_LRS

az storage account create `
    --name "st${TeamName}${Environment}us" `
    --resource-group $ResourceGroupName `
    --location $SecondaryLocation `
    --kind StorageV2 `
    --sku Standard_LRS

az storage account create `
    --name "stshared${TeamName}${Environment}" `
    --resource-group $ResourceGroupName `
    --location $SharedLocation `
    --kind StorageV2 `
    --sku Standard_LRS

#Write-Output "`nCreating VM..."

#az vm create `
#    --name $VmName `
#    --resource-group $ResourceGroupName `
#    --image $VmImage `
#    --admin-username $VmAdminUsername `
#    --admin-password $VmAdminPassword

Write-Output "`nCreating app service plans..."
# https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create

az appservice plan create `
    --name "${AppServicePlanNamePrefix}-eu" `
    --resource-group $ResourceGroupName `
    --location $PrimaryLocation `
    --sku B1 `
    --is-linux

az appservice plan create `
    --name "${AppServicePlanNamePrefix}-us" `
    --resource-group $ResourceGroupName `
    --location $SecondaryLocation `
    --sku B1 `
    --is-linux

Write-Output "`nCreating web apps..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create

az webapp create `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupName `
    --plan "${AppServicePlanNamePrefix}-eu" `
    --runtime PYTHON:3.9

az webapp create `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupName `
    --plan "${AppServicePlanNamePrefix}-us" `
    --runtime PYTHON:3.9

Write-Output "`nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set

az webapp config appsettings set `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupName `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=eu

az webapp config appsettings set `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupName `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=us

foreach ($AppServiceName in $AppServiceNames) {
    Write-Output "`nAssigning identity for app service ${AppServiceName}..."
    # https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign

    $AppServicePrincipalId = (az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName | ConvertFrom-Json).principalId
    Write-Output "Principal ID of app service ${AppServiceName}: ${AppServicePrincipalId}"

    Write-Output "`nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
    Start-Sleep -Seconds 15

    foreach ($StorageAccountName in $StorageAccountNames) {
        if (($AppServiceName.EndsWith("eu") -and $StorageAccountName.EndsWith("us")) -or ($AppServiceName.EndsWith("us") -and $StorageAccountName.EndsWith("eu"))) {
            Write-Output "`nSkipping role assignment for app service ${AppServiceName} in storage account ${StorageAccountName}"
            continue
        }

        Write-Output "`nAdding Storage Blob Data Contributor role for app service ${AppServiceName} in storage account ${StorageAccountName}..."
        # https://learn.microsoft.com/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create

        az role assignment create `
            --assignee-object-id $AppServicePrincipalId `
            --role "Storage Blob Data Contributor" `
            --scope "/subscriptions/${AzureSubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
    }
}

Write-Output "`nDeploying web app code package..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy

az webapp deploy `
    --name "${AppServiceNamePrefix}-eu" `
    --resource-group $ResourceGroupName `
    --type zip `
    --src-path web-app.zip

az webapp deploy `
    --name "${AppServiceNamePrefix}-us" `
    --resource-group $ResourceGroupName `
    --type zip `
    --src-path web-app.zip