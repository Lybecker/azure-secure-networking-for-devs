param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus",
    [string]$HubLocation = "swedencentral"
)

$Environment = "dev"

$ResourceGroupNameHub = "rg-hub-${TeamName}-${Environment}"
$ResourceGroupNameEu = "rg-${TeamName}-${Environment}-eu"
$ResourceGroupNameUs = "rg-${TeamName}-${Environment}-us"

$VnetNameEu = "vnet-${TeamName}-${Environment}-${EuLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${UsLocation}"
$VnetNameHub = "vnet-${TeamName}-${Environment}-${HubLocation}"
$SubnetNameEu = "snet-shared-${TeamName}-${Environment}-${EuLocation}"
$SubnetNameUs = "snet-shared-${TeamName}-${Environment}-${UsLocation}"
$SubnetNameHub = "snet-shared-${TeamName}-${Environment}-${HubLocation}"

$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$AppServiceNameEu = "${AppServiceNamePrefix}-eu"
$AppServiceNameUs = "${AppServiceNamePrefix}-us"
$StorageAccountNameEu = "st${TeamName}${Environment}eu"
$StorageAccountNameUs = "st${TeamName}${Environment}us"
$StorageAccountNameHub = "sthub${TeamName}${Environment}"

$AppServiceInformationEu = (az webapp list --resource-group $ResourceGroupNameEu --query "[?name=='${AppServiceNameEu}']" | ConvertFrom-Json)
$AppServiceResourceIdEu = $AppServiceInformationEu.id
$AppServiceInformationUs = (az webapp list --resource-group $ResourceGroupNameUs --query "[?name=='${AppServiceNameUs}']" | ConvertFrom-Json)
$AppServiceResourceIdUs = $AppServiceInformationUs.id
$StorageAccountInformationEu = (az storage account list --resource-group $ResourceGroupNameEu --query "[?name=='${StorageAccountNameEu}']" | ConvertFrom-Json)
$StorageAccountResourceIdEu = $StorageAccountInformationEu.id
$StorageAccountInformationUs = (az storage account list --resource-group $ResourceGroupNameUs --query "[?name=='${StorageAccountNameUs}']" | ConvertFrom-Json)
$StorageAccountResourceIdUs = $StorageAccountInformationUs.id
$StorageAccountInformationHub = (az storage account list --resource-group $ResourceGroupNameHub --query "[?name=='${StorageAccountNameHub}']" | ConvertFrom-Json)
$StorageAccountResourceIdShared = $StorageAccountInformationHub.id

Write-Output "`nCreating private endpoint for EU app service..."
# https://learn.microsoft.com/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create()

az network private-endpoint create `
    --connection-name "sc-pep-${AppServiceNamePrefix}-eu" `
    --name "pep-${AppServiceNamePrefix}-eu" `
    --private-connection-resource-id $AppServiceResourceIdEu `
    --resource-group $ResourceGroupNameEu `
    --subnet $SubnetNameEu `
    --group-id "sites" `
    --location $EuLocation `
    --nic-name "nic-pep-${AppServiceNamePrefix}-eu" `
    --no-wait false `
    --vnet-name $VnetNameEu

Write-Output "`nCreating private endpoint for US app service..."

az network private-endpoint create `
    --connection-name "sc-pep-${AppServiceNamePrefix}-us" `
    --name "pep-${AppServiceNamePrefix}-us" `
    --private-connection-resource-id $AppServiceResourceIdUs `
    --resource-group $ResourceGroupNameUs `
    --subnet $SubnetNameUs `
    --group-id "sites" `
    --location $UsLocation `
    --nic-name "nic-pep-${AppServiceNamePrefix}-us" `
    --no-wait false `
    --vnet-name $VnetNameUs

Write-Output "`nCreating private endpoint for EU storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameEu}" `
    --name "pep-${StorageAccountNameEu}" `
    --private-connection-resource-id $StorageAccountResourceIdEu `
    --resource-group $ResourceGroupNameEu `
    --subnet $SubnetNameEu `
    --group-id "blob" `
    --location $EuLocation `
    --nic-name "nic-pep-${StorageAccountNameEu}" `
    --no-wait false `
    --vnet-name $VnetNameEu

Write-Output "`nCreating private endpoint for US storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameUs}" `
    --name "pep-${StorageAccountNameUs}" `
    --private-connection-resource-id $StorageAccountResourceIdUs `
    --resource-group $ResourceGroupNameUs `
    --subnet $SubnetNameUs `
    --group-id "blob" `
    --location $UsLocation `
    --nic-name "nic-pep-${StorageAccountNameUs}" `
    --no-wait false `
    --vnet-name $VnetNameUs

Write-Output "`nCreating private endpoint for hub storage account..."

az network private-endpoint create `
    --connection-name "sc-pep-${StorageAccountNameHub}" `
    --name "pep-${StorageAccountNameHub}" `
    --private-connection-resource-id $StorageAccountResourceIdShared `
    --resource-group $ResourceGroupNameHub `
    --subnet $SubnetNameHub `
    --group-id "blob" `
    --location $HubLocation `
    --nic-name "nic-pep-${StorageAccountNameHub}" `
    --no-wait false `
    --vnet-name $VnetNameHub

Write-Output "`nPausing the script to give time for the private endpoints to reach 'Succeeded' state, please wait..."
Start-Sleep -Seconds 90

Write-Output "`nAdding private endpoint of EU app service to DNS zone group..."
# https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group?view=azure-cli-latest#az-network-private-endpoint-dns-zone-group-add()

$PrivateDnsZoneIdWebsites = (az network private-dns zone show --name privatelink.azurewebsites.net --resource-group $ResourceGroupNameHub --query id --output tsv)

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${AppServiceNamePrefix}-eu" `
    --private-dns-zone $PrivateDnsZoneIdWebsites `
    --resource-group $ResourceGroupNameEu `
    --zone-name "privatelink.azurewebsites.net".Replace(".", "-") `
    --name "default" `
    --no-wait false

Write-Output "`nAdding private endpoint of US app service to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${AppServiceNamePrefix}-us" `
    --private-dns-zone $PrivateDnsZoneIdWebsites `
    --resource-group $ResourceGroupNameUs `
    --zone-name "privatelink.azurewebsites.net".Replace(".", "-") `
    --name "default" `
    --no-wait false

Write-Output "`nAdding private endpoint of EU storage account to DNS zone group..."

$PrivateDnsZoneIdBlob = (az network private-dns zone show --name privatelink.blob.core.windows.net --resource-group $ResourceGroupNameHub --query id --output tsv)

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameEu}" `
    --private-dns-zone $PrivateDnsZoneIdBlob `
    --resource-group $ResourceGroupNameEu `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait false

Write-Output "`nAdding private endpoint of US storage account to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameUs}" `
    --private-dns-zone $PrivateDnsZoneIdBlob `
    --resource-group $ResourceGroupNameUs `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait false

Write-Output "`nAdding private endpoint of hub storage account to DNS zone group..."

az network private-endpoint dns-zone-group add `
    --endpoint-name "pep-${StorageAccountNameHub}" `
    --private-dns-zone $PrivateDnsZoneIdBlob `
    --resource-group $ResourceGroupNameHub `
    --zone-name "privatelink.blob.core.windows.net".Replace(".", "-") `
    --name "default" `
    --no-wait false

Write-Output "`nDisabling public access to EU app service..."
# https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update()

az resource update `
    --resource-group $ResourceGroupNameEu `
    --name $AppServiceNameEu `
    --resource-type "Microsoft.Web/sites" `
    --set properties.publicNetworkAccess=Disabled

Write-Output "`nDisabling public access to US app service..."

az resource update `
    --resource-group $ResourceGroupNameUs `
    --name $AppServiceNameUs `
    --resource-type "Microsoft.Web/sites" `
    --set properties.publicNetworkAccess=Disabled

#Write-Output "`nDisabling public access to storage accounts..."
#.\2-3-2-storage-accounts-disable-public-access.ps1 -TeamName $TeamName
