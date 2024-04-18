#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US, $env:ASNFD_RESOURCE_GROUP_NAME_HUB)
$Locations = @($HubLocation, $EuLocation, $UsLocation)
$VnetNames = @($env:ASNFD_VNET_NAME_EU, $env:ASNFD_VNET_NAME_US, $env:ASNFD_VNET_NAME_HUB)
$SubnetNames = @($env:ASNFD_DEFAULT_SNET_NAME_EU, $env:ASNFD_DEFAULT_SNET_NAME_US, $env:ASNFD_DEFAULT_SNET_NAME_HUB)

for ($i = 0; $i -lt 3; $i++) {
    $ResourceGroupName = $ResourceGroupNames[$i]
    $Location = $Locations[$i]
    $SubnetName = $SubnetNames[$i]
    $NetworkSecurityGroupName = "nsg-${SubnetName}"
    $VnetName = $VnetNames[$i]

    Write-Output "`nCreating network security group `"${NetworkSecurityGroupName}`" (resource group `"${ResourceGroupName}`")..."
    az network nsg create `
        --name $NetworkSecurityGroupName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --no-wait false

    Write-Output "`nCreating network security group rule to deny all traffic to storage accounts..."
    az network nsg rule create `
        --name "DenyAllToStorageInbound" `
        --resource-group $ResourceGroupName `
        --nsg-name $NetworkSecurityGroupName `
        --priority "220" `
        --access "Deny" `
        --description "Denies all inbound traffic to storage accounts" `
        --destination-address-prefixes "Storage" `
        --destination-port-ranges "*" `
        --direction "Inbound" `
        --protocol "*" `
        --source-port-ranges "*" `
        --no-wait false

    Write-Output "`nCreating network security group rule to allow app services to access storage accounts..."
    az network nsg rule create `
        --name "AllowAppServiceToStorageInbound" `
        --resource-group $ResourceGroupName `
        --nsg-name $NetworkSecurityGroupName `
        --priority "200" `
        --access "Allow" `
        --description "Allow inbound traffic to storage accounts from app services" `
        --destination-address-prefixes "Storage" `
        --destination-port-ranges 80 443 `
        --direction "Inbound" `
        --protocol "*" `
        --source-address-prefixes "AppService" `
        --source-port-ranges "*" `
        --no-wait false

    Write-Output "`nUpdating subnet `"${SubnetName}`"..."
    # See https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-update
    az network vnet subnet update `
        --name $SubnetName `
        --network-security-group $NetworkSecurityGroupName `
        --private-endpoint-network-policies NetworkSecurityGroupEnabled `
        --resource-group $ResourceGroupName `
        --vnet-name $VnetName
}
