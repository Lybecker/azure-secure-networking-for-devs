#!/bin/bash
set -e

TeamName=$1
Location="westeurope"
if [ -z "$TeamName" ]; then
  echo >&2 "Required parameter \"TeamName\" missing"
  exit 1
fi


Environment="dev"
ResourceGroupName="rg-${TeamName}-${Environment}"
StorageAccountName="st${TeamName}${Environment}"
VmName="vm${TeamName}"
VmImage="MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:22621.1265.230207" # URN format for '--image': "Publisher:Offer:Sku:Version"
VmAdminUsername=$TeamName
VmAdminPassword="${TeamName}Password123!"
AppServicePlanName="plan-${TeamName}-${Environment}"
AppServiceName="app-${TeamName}-${Environment}"

echo -e "\nCreating resource group..."

az group create --name $ResourceGroupName --location $Location

echo -e "\nCreating storage account..."

az storage account create \
    --name $StorageAccountName \
    --resource-group $ResourceGroupName \
    --location $Location \
    --sku Standard_LRS

echo -e "\nCreating VM..."

az vm create \
    --name $VmName \
    --resource-group $ResourceGroupName \
    --image $VmImage \
    --admin-username $VmAdminUsername \
    --admin-password $VmAdminPassword

echo -e "\nCreating app service plan..."

az appservice plan create \
    --name $AppServicePlanName \
    --resource-group $ResourceGroupName \
    --sku B1 \
    --is-linux

echo -e "\nCreating web app..."

az webapp create \
    --name $AppServiceName \
    --resource-group $ResourceGroupName \
    --plan $AppServicePlanName \
    --runtime PYTHON:3.9

echo -e "\nEnabling web app build automation..."

az webapp config appsettings set \
    --name $AppServiceName \
    --resource-group $ResourceGroupName \
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

echo -e "\nDeploying web app code package..."

az webapp deploy \
    --name $AppServiceName \
    --resource-group $ResourceGroupName \
    --type zip \
    --src-path web-app.zip
