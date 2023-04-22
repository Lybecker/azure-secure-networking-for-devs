param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "swedencentral"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"

$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNameEu = "${AppServiceNamePrefix}-eu"
$AppServiceNameUs = "${AppServiceNamePrefix}-us"

$VnetNameEu = "vnet-${TeamName}-${Environment}-${PrimaryLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${SecondaryLocation}"
$SubnetNameEu = "snet-apps-${TeamName}-${Environment}-${PrimaryLocation}"
$SubnetNameUs = "snet-apps-${TeamName}-${Environment}-${SecondaryLocation}"

Write-Output "`nAdding VNET integration for app service ${AppServiceNameEu} using virtual network and subnet ${VnetNameEu}/${SubnetNameEu}..."
# https://learn.microsoft.com/cli/azure/webapp/vnet-integration?view=azure-cli-latest#az-webapp-vnet-integration-add

az webapp vnet-integration add `
    --name $AppServiceNameEu `
    --resource-group $ResourceGroupName `
    --subnet $SubnetNameEu `
    --vnet $VnetNameEu `
    --skip-delegation-check false

Write-Output "`nAdding VNET integration for app service ${AppServiceNameUs} using virtual network and subnet ${VnetNameUs}/${SubnetNameUs}..."

az webapp vnet-integration add `
    --name $AppServiceNameUs `
    --resource-group $ResourceGroupName `
    --subnet $SubnetNameUs `
    --vnet $VnetNameUs `
    --skip-delegation-check false
