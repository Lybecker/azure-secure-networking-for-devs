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

$Environment = "dev"

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation -Environment $Environment

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US, $env:ASNFD_RESOURCE_GROUP_NAME_HUB)
$Locations = @($EuLocation, $UsLocation, $HubLocation)
$AppAsgNames = @("asg-app-${TeamName}-${Environment}-eu", "asg-app-${TeamName}-${Environment}-us")
$StorageAsgNames = @("asg-storage-${TeamName}-${Environment}-eu", "asg-storage-${TeamName}-${Environment}-us", "asg-storage-${TeamName}-${Environment}-hub")
$StorageAccountNames = @($env:ASNFD_STORAGE_ACCOUNT_NAME_EU, $env:ASNFD_STORAGE_ACCOUNT_NAME_US, $env:ASNFD_STORAGE_ACCOUNT_NAME_HUB)
$VnetNames = @($env:ASNFD_VNET_NAME_EU, $env:ASNFD_VNET_NAME_US, $env:ASNFD_VNET_NAME_HUB)
$DefaultSubnetNames = @($env:ASNFD_DEFAULT_SNET_NAME_EU, $env:ASNFD_DEFAULT_SNET_NAME_US, $env:ASNFD_DEFAULT_SNET_NAME_HUB)
$AppSubnetNames = @($env:ASNFD_APPS_SNET_NAME_EU, $env:ASNFD_APPS_SNET_NAME_US)

for ($i = 0; $i -lt 2; $i++) {
    $ResourceGroupName = $ResourceGroupNames[$i]
    $Location = $Locations[$i]
    $StorageAsgName = $StorageAsgNames[$i]
    $StorageAccountName = $StorageAccountNames[$i]
    $StorageAccountPrivateEndpointName = "pep-${StorageAccountName}"
    $DefaultSubnetName = $DefaultSubnetNames[$i]
    $AppSubnetName = $AppSubnetNames[$i]
    $NetworkSecurityGroupName = "nsg-${DefaultSubnetName}"
    $VnetName = $VnetNames[$i]

    Write-Output "`nCreating application security group `"${StorageAsgName}`" (resource group `"${ResourceGroupName}`")..."
    # https://learn.microsoft.com/cli/azure/network/asg?view=azure-cli-latest#az-network-asg-create
    az network asg create `
        --name $StorageAsgName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --no-wait false

    $StorageAsgId = $(az network asg show --name $StorageAsgName --resource-group $ResourceGroupName --query id)

    if ($StorageAsgId.Length -eq 0) {
        Write-Error "Failed to retrieve the ID of the newly created application security group `"${StorageAsgName}`""
        exit 1
    }

    Write-Output "`nAssociating application security group `"${StorageAsgName}`" with private endpoint of storage account `"${StorageAccountName}`"..."
    # https://learn.microsoft.com/cli/azure/network/private-endpoint/asg?view=azure-cli-latest#az-network-private-endpoint-asg-add
    az network private-endpoint asg add `
        --endpoint-name $StorageAccountPrivateEndpointName `
        --resource-group $ResourceGroupName `
        --asg-id $StorageAsgId `
        --no-wait false

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
        --destination-asgs $StorageAsgId `
        --destination-port-ranges "*" `
        --direction "Inbound" `
        --protocol "*" `
        --source-port-ranges "*" `
        --no-wait false

    # https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-show
    $AppSubnetAddressPrefix = $(az network vnet subnet show --resource-group $ResourceGroupName --name $AppSubnetName --vnet-name $VnetName --query addressPrefix)

    if ($AppSubnetAddressPrefix.Length -eq 0) {
        Write-Error "Failed to retrieve the address prefix of subnet `"${AppSubnetName}`""
        exit 1
    }

    Write-Output "`nCreating network security group rule to allow access to storage ASG `"${StorageAsgName}`" from subnet `"${AppSubnetName}`" (address range ${AppSubnetAddressPrefix})..."
    az network nsg rule create `
        --name "AllowAppServiceToStorageInbound" `
        --resource-group $ResourceGroupName `
        --nsg-name $NetworkSecurityGroupName `
        --priority "200" `
        --access "Allow" `
        --description "Allow inbound traffic to storage account from app service" `
        --destination-asgs $StorageAsgId `
        --destination-port-ranges 80 443 `
        --direction "Inbound" `
        --protocol "*" `
        --source-address-prefixes $AppSubnetAddressPrefix `
        --source-port-ranges "*" `
        --no-wait false

    Write-Output "`nUpdating subnet `"${SubnetName}`"..."
    # See https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-update
    az network vnet subnet update `
        --name $DefaultSubnetName `
        --network-security-group $NetworkSecurityGroupName `
        --private-endpoint-network-policies NetworkSecurityGroupEnabled `
        --resource-group $ResourceGroupName `
        --vnet-name $VnetName
}
