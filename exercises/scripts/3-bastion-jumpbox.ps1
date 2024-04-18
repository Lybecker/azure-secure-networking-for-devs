#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$Location = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$Environment = "dev"
$ResourceGroupNameHub = $env:ASNFD_RESOURCE_GROUP_NAME_HUB
$VnetName = $env:ASNFD_VNET_NAME_HUB
$JumpboxNsgName = $env:ASNFD_JUMPBOX_NSG_NAME
$BastionPublicIpAddressName = "pip-bastion-${TeamName}-${Environment}"
$BastionName = "bas-${TeamName}-${Environment}"

.\subscripts\2-1-subnet.ps1 `
    -SubnetName "AzureBastionSubnet" `
    -ResourceGroupName $ResourceGroupNameHub `
    -AddressPrefixes "10.0.0.64/26" `
    -VnetName $env:ASNFD_VNET_NAME_HUB

Write-Output "`nCreating rule to deny all inbound traffic for NSG..."
# Update Azure CLI (az upgrade) in case running into this bug: https://github.com/Azure/azure-cli/issues/24939
# https://learn.microsoft.com/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create()

az network nsg rule create `
    --name "DenyAllInbound" `
    --resource-group $ResourceGroupNameHub `
    --nsg-name $JumpboxNsgName `
    --priority "200" `
    --access "Deny" `
    --description "Denies all inbound traffic" `
    --direction "Inbound" `
    --protocol "*" `
    --no-wait false

Write-Output "`nCreating public IP address for Azure Bastion..."
# https://learn.microsoft.com/cli/azure/network/public-ip?view=azure-cli-latest#az-network-public-ip-create()

az network public-ip create `
    --name $BastionPublicIpAddressName `
    --resource-group $ResourceGroupNameHub `
    --location $Location `
    --sku Standard

Write-Output "`nCreating Azure Bastion resource..."
# https://learn.microsoft.com/cli/azure/network/bastion?view=azure-cli-latest#az-network-bastion-create()

az network bastion create `
    --name $BastionName `
    --resource-group $ResourceGroupNameHub `
    --location $Location `
    --vnet-name $VnetName `
    --public-ip-address $BastionPublicIpAddressName
