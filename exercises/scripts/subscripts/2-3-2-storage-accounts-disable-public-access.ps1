param(
    [Parameter(Mandatory=$True)][string]$TeamName
)

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US, $env:ASNFD_RESOURCE_GROUP_NAME_HUB)
$StorageAccountNames = @($env:ASNFD_STORAGE_ACCOUNT_NAME_EU, $env:ASNFD_STORAGE_ACCOUNT_NAME_US, $env:ASNFD_STORAGE_ACCOUNT_NAME_HUB)

for ($i = 0; $i -lt 3; $i++) {
    $StorageAccountName = $StorageAccountNames[$i]
    $ResourceGroupName = $ResourceGroupNames[$i]

    Write-Output "`nDisabling public access to storage account ${StorageAccountName}..."
    # https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update()

    az resource update `
        --resource-group $ResourceGroupName `
        --name $StorageAccountName `
        --resource-type "Microsoft.Storage/storageAccounts" `
        --set properties.publicNetworkAccess=Disabled
}
