#!/bin/bash
set -e

TeamName=$1
PrimaryLocation="westeurope"
SecondaryLocation="eastus"
SharedLocation="swedencentral"
if [ -z "$TeamName" ]; then
  echo >&2 "Required parameter \"TeamName\" missing"
  exit 1
fi


Environment="dev"
ResourceGroupName="rg-${TeamName}-${Environment}"
StorageAccountNames=("st${TeamName}${Environment}eu" "st${TeamName}${Environment}us" "stshared${TeamName}${Environment}")
AppServicePlanNamePrefix="plan-${TeamName}-${Environment}"
AppServiceNamePrefix="app-${TeamName}-${Environment}"
AppServiceNames=("${AppServiceNamePrefix}-eu" "${AppServiceNamePrefix}-us")

AzureAccountInformation=$(az account show)
AzureSubscriptionId=$(echo "$AzureAccountInformation" | jq -r '.id')

echo -e "\nAzure subscription ID: ${AzureSubscriptionId}"

echo -e "\nCreating resource group ${ResourceGroupName}..."

az group create --name $ResourceGroupName --location $PrimaryLocation

echo -e "\nCreating storage accounts..."
# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create

az storage account create \
    --name "st${TeamName}${Environment}eu" \
    --resource-group $ResourceGroupName \
    --location $PrimaryLocation \
    --kind StorageV2 \
    --sku Standard_LRS

az storage account create \
    --name "st${TeamName}${Environment}us" \
    --resource-group $ResourceGroupName \
    --location $SecondaryLocation \
    --kind StorageV2 \
    --sku Standard_LRS

az storage account create \
    --name "stshared${TeamName}${Environment}" \
    --resource-group $ResourceGroupName \
    --location $SharedLocation \
    --kind StorageV2 \
    --sku Standard_LRS

echo -e "\nCreating app service plans..."
# https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create

az appservice plan create \
    --name "${AppServicePlanNamePrefix}-eu" \
    --resource-group $ResourceGroupName \
    --location $PrimaryLocation \
    --sku B1 \
    --is-linux

az appservice plan create \
    --name "${AppServicePlanNamePrefix}-us" \
    --resource-group $ResourceGroupName \
    --location $SecondaryLocation \
    --sku B1 \
    --is-linux

echo -e "\nCreating web apps..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create

az webapp create \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group $ResourceGroupName \
    --plan "${AppServicePlanNamePrefix}-eu" \
    --runtime PYTHON:3.9

az webapp create \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group $ResourceGroupName \
    --plan "${AppServicePlanNamePrefix}-us" \
    --runtime PYTHON:3.9

echo -e "\nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set

az webapp config appsettings set \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group $ResourceGroupName \
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=eu

az webapp config appsettings set \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group $ResourceGroupName \
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=us

for AppServiceName in ${AppServiceNames[@]}; do
    echo -e "\nAssigning identity for app service ${AppServiceName}..."
    # https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign

    IdentityOutput=$(az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName)
    AppServicePrincipalId=$(echo "$IdentityOutput" | jq -r '.principalId')
    echo -e "Principal ID of app service ${AppServiceName}: ${AppServicePrincipalId}"

    echo -e "\nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
    sleep 15

    for StorageAccountName in ${StorageAccountNames[@]}; do
        if ([[ "$AppServiceName" == *eu ]] && [[ "$StorageAccountName" == *us ]]) || ([[ "$AppServiceName" == *us ]] && [[ "$StorageAccountName" == *eu ]]); then
            echo -e "\nSkipping role assignment for app service ${AppServiceName} in storage account ${StorageAccountName}"
            continue
        fi

        echo -e "\nAdding Storage Blob Data Contributor role for app service ${AppServiceName} in storage account ${StorageAccountName}..."
        # https://learn.microsoft.com/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create

        Scope="/subscriptions/${AzureSubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"

        MSYS_NO_PATHCONV=1 az role assignment create \
            --assignee-object-id "$AppServicePrincipalId" \
            --role "Storage Blob Data Contributor" \
            --scope "$Scope"
    done
done

echo -e "\nDeploying web app code package..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy

az webapp deploy \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group $ResourceGroupName \
    --type zip \
    --src-path web-app.zip

az webapp deploy \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group $ResourceGroupName \
    --type zip \
    --src-path web-app.zip
