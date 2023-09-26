param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus",
    [string]$HubLocation = "swedencentral"
)

$Environment = "dev"

$ResourceGroupNameEu = "rg-${TeamName}-${Environment}-eu"
$ResourceGroupNameUs = "rg-${TeamName}-${Environment}-us"

$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNameEu = "${AppServiceNamePrefix}-eu"
$AppServiceNameUs = "${AppServiceNamePrefix}-us"

$VnetNameEu = "vnet-${TeamName}-${Environment}-${EuLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${UsLocation}"
$SubnetNameEu = "snet-apps-${TeamName}-${Environment}-${EuLocation}"
$SubnetNameUs = "snet-apps-${TeamName}-${Environment}-${UsLocation}"

Write-Output "`nAdding VNET integration for app service ${AppServiceNameEu} using virtual network and subnet ${VnetNameEu}/${SubnetNameEu}..."
# https://learn.microsoft.com/cli/azure/webapp/vnet-integration?view=azure-cli-latest#az-webapp-vnet-integration-add

az webapp vnet-integration add `
    --name $AppServiceNameEu `
    --resource-group $ResourceGroupNameEu `
    --subnet $SubnetNameEu `
    --vnet $VnetNameEu `
    --skip-delegation-check false

Write-Output "`nAdding VNET integration for app service ${AppServiceNameUs} using virtual network and subnet ${VnetNameUs}/${SubnetNameUs}..."

az webapp vnet-integration add `
    --name $AppServiceNameUs `
    --resource-group $ResourceGroupNameUs `
    --subnet $SubnetNameUs `
    --vnet $VnetNameUs `
    --skip-delegation-check false
