param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "northeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$VnetNameEu = "vnet-${TeamName}-${Environment}-${PrimaryLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${SecondaryLocation}"
$VnetNameShared = "vnet-${TeamName}-${Environment}-${SharedLocation}"
$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNameEu = "${AppServiceNamePrefix}-eu"
$AppServiceNameUs = "${AppServiceNamePrefix}-us"
$StorageAccountNameEu = "st${TeamName}${Environment}eu"
$StorageAccountNameUs = "st${TeamName}${Environment}us"
$StorageAccountNameShared = "stshared${TeamName}${Environment}"

$AppServiceInformationEu = (az webapp list --resource-group $ResourceGroupName --query "[?name=='${AppServiceNameEu}']" | ConvertFrom-Json)
$AppServiceResourceIdEu = $AppServiceInformationEu.id
$AppServiceInformationUs = (az webapp list --resource-group $ResourceGroupName --query "[?name=='${AppServiceNameUs}']" | ConvertFrom-Json)
$AppServiceResourceIdUs = $AppServiceInformationUs.id
$StorageAccountInformationEu = (az storage account list --resource-group $ResourceGroupName --query "[?name=='${StorageAccountNameEu}']" | ConvertFrom-Json)
$StorageAccountResourceIdEu = $StorageAccountInformationEu.id
$StorageAccountInformationUs = (az storage account list --resource-group $ResourceGroupName --query "[?name=='${StorageAccountNameUs}']" | ConvertFrom-Json)
$StorageAccountResourceIdUs = $StorageAccountInformationUs.id
$StorageAccountInformationShared = (az storage account list --resource-group $ResourceGroupName --query "[?name=='${StorageAccountNameShared}']" | ConvertFrom-Json)
$StorageAccountResourceIdShared = $StorageAccountInformationShared.id

Write-Output "`nCreating private endpoint for EU app service..."
# https://learn.microsoft.com/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create

az network private-endpoint create `
    --connection-name "sc-pep-${AppServiceNamePrefix}-eu" `
    --name "pep-${AppServiceNamePrefix}-eu" `
    --private-connection-resource-id $AppServiceResourceIdEu `
    --resource-group $ResourceGroupName `
    --subnet "snet-shared-${TeamName}-${Environment}-${PrimaryLocation}" `
    --group-id "sites" `
    --location $PrimaryLocation `
    --nic-name "nic-${AppServiceNamePrefix}-eu" `
    --no-wait true `
    --vnet-name $VnetNameEu

Write-Output "`nCreating private endpoint for US app service..."

az network private-endpoint create `
    --connection-name "sc-pep-${AppServiceNamePrefix}-us" `
    --name "pep-${AppServiceNamePrefix}-us" `
    --private-connection-resource-id $AppServiceResourceIdUs `
    --resource-group $ResourceGroupName `
    --subnet "snet-shared-${TeamName}-${Environment}-${SecondaryLocation}" `
    --group-id "sites" `
    --location $SecondaryLocation `
    --nic-name "nic-${AppServiceNamePrefix}-us" `
    --no-wait true `
    --vnet-name $VnetNameUs

Write-Output "`nCreating private endpoint for EU storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameEu}" `
    --name "pep-${StorageAccountNameEu}" `
    --private-connection-resource-id $StorageAccountResourceIdEu `
    --resource-group $ResourceGroupName `
    --subnet "snet-shared-${TeamName}-${Environment}-${PrimaryLocation}" `
    --group-id "blob" `
    --location $PrimaryLocation `
    --nic-name "nic-${StorageAccountNameEu}" `
    --no-wait true `
    --vnet-name $VnetNameEu

Write-Output "`nCreating private endpoint for US storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameUs}" `
    --name "pep-${StorageAccountNameUs}" `
    --private-connection-resource-id $StorageAccountResourceIdUs `
    --resource-group $ResourceGroupName `
    --subnet "snet-shared-${TeamName}-${Environment}-${SecondaryLocation}" `
    --group-id "blob" `
    --location $SecondaryLocation `
    --nic-name "nic-${StorageAccountNameUs}" `
    --no-wait true `
    --vnet-name $VnetNameUs

Write-Output "`nCreating private endpoint for shared storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameShared}" `
    --name "pep-${StorageAccountNameShared}" `
    --private-connection-resource-id $StorageAccountResourceIdShared `
    --resource-group $ResourceGroupName `
    --subnet "snet-shared-${TeamName}-${Environment}-${SharedLocation}" `
    --group-id "blob" `
    --location $SharedLocation `
    --nic-name "nic-${StorageAccountNameShared}" `
    --no-wait true `
    --vnet-name $VnetNameShared

Write-Output "`nAdding private endpoint of EU app service to DNS zone group..."
# https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group?view=azure-cli-latest#az-network-private-endpoint-dns-zone-group-add

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${AppServiceNamePrefix}-eu" `
    --private-dns-zone "privatelink.azurewebsites.net" `
    --resource-group $ResourceGroupName `
    --zone-name "privatelink.azurewebsites.net".Replace(".", "-") `
    --name "default" `
    --no-wait true

Write-Output "`nAdding private endpoint of US app service to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${AppServiceNamePrefix}-us" `
    --private-dns-zone "privatelink.azurewebsites.net" `
    --resource-group $ResourceGroupName `
    --zone-name "privatelink.azurewebsites.net".Replace(".", "-") `
    --name "default" `
    --no-wait true

Write-Output "`nAdding private endpoint of EU storage account to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameEu}" `
    --private-dns-zone "privatelink.blob.core.windows.net" `
    --resource-group $ResourceGroupName `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait true

Write-Output "`nAdding private endpoint of US storage account to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameUs}" `
    --private-dns-zone "privatelink.blob.core.windows.net" `
    --resource-group $ResourceGroupName `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait true

Write-Output "`nAdding private endpoint of shared storage account to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameShared}" `
    --private-dns-zone "privatelink.blob.core.windows.net" `
    --resource-group $ResourceGroupName `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait true

Write-Output "`nDisabling public access to EU app service..."
# https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update

az resource update `
    --resource-group $ResourceGroupName `
    --name $AppServiceNameEu `
    --resource-type "Microsoft.Web/sites" `
    --set properties.publicNetworkAccess=Disabled

Write-Output "`nDisabling public access to US app service..."

az resource update `
    --resource-group $ResourceGroupName `
    --name $AppServiceNameUs `
    --resource-type "Microsoft.Web/sites" `
    --set properties.publicNetworkAccess=Disabled
