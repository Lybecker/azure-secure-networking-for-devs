param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "westeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$VnetName = "vnet-${TeamName}-${Location}-${Environment}"
$SharedSubnetName = "snet-${TeamName}-shared-${Environment}"

Write-Output "`nCreating resource group..."
az group create --name $ResourceGroupName --location $Location

Write-Output "`nCreating virtual network..."

az network vnet create `
    --name $VnetName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --address-prefixes "10.0.0.0/22"

Write-Output "`nCreating subnet for Azure Bastion..."

az network vnet subnet create `
    --name "AzureBastionSubnet" `
    --resource-group $ResourceGroupName `
    --vnet-name $VnetName `
    --address-prefixes "10.0.0.0/26" `
    --disable-private-endpoint-network-policies false `
    --disable-private-link-service-network-policies false

Write-Output "`nCreating subnet for shared resources..."

az network vnet subnet create `
    --name $SharedSubnetName `
    --resource-group $ResourceGroupName `
    --vnet-name $VnetName `
    --address-prefixes "10.0.0.64/26" `
    --disable-private-endpoint-network-policies false `
    --disable-private-link-service-network-policies false `
    --service-endpoints Microsoft.KeyVault Microsoft.Storage
