param(
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$StorageAccountName,
    [Parameter(Mandatory=$True)][string]$VnetName,
    [Parameter(Mandatory=$True)][string]$SubnetName
)

Write-Output "`nDisabling public access to storage account ${StorageAccountName}..."

# https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update

az resource update `
    --resource-group $ResourceGroupName `
    --name $StorageAccountName `
    --resource-type "Microsoft.Storage/storageAccounts" `
    --set properties.publicNetworkAccess=Enabled

# https://learn.microsoft.com/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-update

#az storage account update `
#    --resource-group $ResourceGroupName `
#    --name $StorageAccountName `
#    --public-network-access Enabled

az storage account update `
    --resource-group $ResourceGroupName `
    --name $StorageAccountName `
    --default-action Deny

$SubnetResourceId = (az network vnet subnet show --resource-group $ResourceGroupName --vnet-name $VnetName --name $SubnetName | ConvertFrom-Json).id

# https://learn.microsoft.com/cli/azure/storage/account/network-rule?view=azure-cli-latest

az storage account network-rule add `
    --resource-group $ResourceGroupName `
    --account-name $StorageAccountName `
    --subnet $SubnetResourceId
