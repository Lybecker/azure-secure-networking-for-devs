#!/bin/bash

TeamName=$1
Location="westeurope"
if [ -z "$TeamName" ]; then
  echo >&2 "Required parameter \"TeamName\" missing"
  exit 1
fi


Environment="dev"
ResourceGroupName="rg-${TeamName}-${Environment}"
VnetName="vnet-${TeamName}-${Location}-${Environment}"
JumpboxName="jumpbox-${TeamName}-${Environment}"
JumpboxSubnetName="snet-${TeamName}-shared-${Environment}"
JumpboxAdminUsername="jumpboxuser"
JumpboxAdminPass="Jumpbox123"
BastionPublicIpAddressName="pip-${TeamName}-bastion-${Environment}"
BastionName="bas-${TeamName}-${Environment}"

# TODO: Create jumpbox

echo -e "\nCreating public IP address for Azure Bastion..."

az network public-ip create \
    --name $BastionPublicIpAddressName \
    --resource-group $ResourceGroupName \
    --location $Location \
    --sku Standard

echo -e "\nCreating Azure Bastion resource..."

az network bastion create \
    --name $BastionName \
    --resource-group $ResourceGroupName \
    --location $Location \
    --vnet-name $VnetName \
    --public-ip-address $BastionPublicIpAddressName
