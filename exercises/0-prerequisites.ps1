param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "westeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$StorageAccountName = "st${TeamName}${Environment}"
$VmName = "vm${TeamName}"
$VmImage = "MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:22621.1265.230207" # URN format for '--image': "Publisher:Offer:Sku:Version"
$VmAdminUsername = $TeamName
$VmAdminPassword = "${TeamName}Password123!"
$AppServicePlanName = "plan-${TeamName}-${Environment}"
$AppServiceName = "app-${TeamName}-${Environment}"

Write-Output "`nCreating resource group..."

az group create --name $ResourceGroupName --location $Location

Write-Output "`nCreating storage account..."

az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS

Write-Output "`nCreating VM..."

az vm create `
    --name $VmName `
    --resource-group $ResourceGroupName `
    --image $VmImage `
    --admin-username $VmAdminUsername `
    --admin-password $VmAdminPassword

Write-Output "`nCreating app service plan..."

az appservice plan create `
    --name $AppServicePlanName `
    --resource-group $ResourceGroupName `
    --sku B1 `
    --is-linux

Write-Output "`nCreating web app..."

az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlanName `
    --runtime PYTHON:3.9

Write-Output "`nEnabling web app build automation..."

az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

Write-Output "`nDeploying web app code package..."

az webapp deploy `
    --name $AppServiceName `
    --resource-group $ResourceGroupName `
    --type zip `
    --src-path web-app.zip
