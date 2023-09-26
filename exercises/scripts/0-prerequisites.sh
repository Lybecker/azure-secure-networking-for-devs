#!/bin/bash
# This script is tested to work Azure CLI 2.52.0
set -e

TeamName=$TEAM_NAME
HubLocation=$HUB_LOCATION
EuLocation=$EU_LOCATION
UsLocation=$US_LOCATION

if [ -z "$TeamName" ]; then
  echo >&2 "Required parameter \"TeamName\" missing"
  exit 1
fi

echo -e "\nUsing config:\n  - Team name: ${TeamName}\n  - Hub location: ${HubLocation}\n  - EU location: ${EuLocation}\n  - US location: ${UsLocation}"

Locations=("$HubLocation" "$EuLocation" "$UsLocation")
Environment="dev"
ResourceGroupNames=("rg-hub-${TeamName}-${Environment}" "rg-${TeamName}-${Environment}-eu" "rg-${TeamName}-${Environment}-us")
StorageAccountNames=("sthub${TeamName}${Environment}" "st${TeamName}${Environment}eu" "st${TeamName}${Environment}us")
AppServicePlanNamePrefix="asp-${TeamName}-${Environment}"
AppServiceNamePrefix="app-${TeamName}-${Environment}"
AppServiceNames=("${AppServiceNamePrefix}-eu" "${AppServiceNamePrefix}-us")

AzureAccountInformation=$(az account show)
AzureSubscriptionId=$(echo "$AzureAccountInformation" | jq -r '.id')

echo -e "\nAzure subscription ID: ${AzureSubscriptionId}"

for i in {0..2}; do
    echo -e "\nCreating resource group \"${ResourceGroupNames[$i]}\" in location \"${Locations[$i]}\"..."
    az group create --name "${ResourceGroupNames[$i]}" --location "${Locations[$i]}"
done

echo -e "\nCreating storage accounts..."
# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create

for i in {0..2}; do
    echo -e "\nCreating storage account group \"${StorageAccountNames[$i]}\" in location \"${Locations[$i]}\"..."

    az storage account create \
        --name "${StorageAccountNames[$i]}" \
        --resource-group "${ResourceGroupNames[$i]}" \
        --location "${Locations[$i]}" \
        --kind StorageV2 \
        --sku Standard_LRS
done

echo -e "\nCreating app service plans..."
# https://learn.microsoft.com/cli/azure/appservice/plan?view=azure-cli-latest#az-appservice-plan-create

AppServicePlanSku="S1"

az appservice plan create \
    --name "${AppServicePlanNamePrefix}-eu" \
    --resource-group "${ResourceGroupNames[1]}" \
    --location $EuLocation \
    --sku $AppServicePlanSku \
    --is-linux

az appservice plan create \
    --name "${AppServicePlanNamePrefix}-us" \
    --resource-group "${ResourceGroupNames[2]}" \
    --location $UsLocation \
    --sku $AppServicePlanSku \
    --is-linux

echo -e "\nCreating web apps..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-create

az webapp create \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group "${ResourceGroupNames[1]}" \
    --plan "${AppServicePlanNamePrefix}-eu" \
    --runtime PYTHON:3.9

az webapp create \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group "${ResourceGroupNames[2]}" \
    --plan "${AppServicePlanNamePrefix}-us" \
    --runtime PYTHON:3.9

echo -e "\nEnabling web app build automation and configuring app settings..."
# https://learn.microsoft.com/cli/azure/webapp/config/appsettings?view=azure-cli-latest#az-webapp-config-appsettings-set

az webapp config appsettings set \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group "${ResourceGroupNames[1]}" \
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=eu

az webapp config appsettings set \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group "${ResourceGroupNames[2]}" \
    --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true TEAM_NAME=$TeamName LOCATION=us

for i in {0..1}; do
    AppServiceName="${AppServiceNames[i]}"
    echo -e "\nAssigning identity for app service ${AppServiceName}..."
    # https://learn.microsoft.com/cli/azure/webapp/identity?view=azure-cli-latest#az-webapp-identity-assign

    ResourceGroupNameIndex=$((i+1))

    IdentityOutput=$(az webapp identity assign --resource-group ${ResourceGroupNames[$ResourceGroupNameIndex]} --name $AppServiceName)
    AppServicePrincipalId=$(echo "$IdentityOutput" | jq -r '.principalId')
    echo -e "Principal ID of app service ${AppServiceName}: ${AppServicePrincipalId}"

    echo -e "\nPausing the script to give time for the previous operation(s) to take an effect, please wait..."
    sleep 15

    for j in {0..2}; do
        StorageAccountName="${StorageAccountNames[$j]}"

        if ([[ "$AppServiceName" == *eu ]] && [[ "$StorageAccountName" == *us ]]) || ([[ "$AppServiceName" == *us ]] && [[ "$StorageAccountName" == *eu ]]); then
            echo -e "\nSkipping role assignment for app service ${AppServiceName} in storage account ${StorageAccountName}"
            continue
        fi

        echo -e "\nAdding Storage Blob Data Contributor role for app service ${AppServiceName} in storage account ${StorageAccountName}..."
        # https://learn.microsoft.com/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create

        Scope="/subscriptions/${AzureSubscriptionId}/resourceGroups/${ResourceGroupNames[$j]}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"

        MSYS_NO_PATHCONV=1 az role assignment create \
            --assignee-object-id "$AppServicePrincipalId" \
            --assignee-principal-type ServicePrincipal \
            --role "Storage Blob Data Contributor" \
            --scope "$Scope"
    done
done

echo -e "\nDeploying web app code package..."
# https://learn.microsoft.com/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy

az webapp deploy \
    --name "${AppServiceNamePrefix}-eu" \
    --resource-group "${ResourceGroupNames[1]}" \
    --type zip \
    --src-path ../../src/web-app.zip

az webapp deploy \
    --name "${AppServiceNamePrefix}-us" \
    --resource-group "${ResourceGroupNames[2]}" \
    --type zip \
    --src-path ../../src/web-app.zip
