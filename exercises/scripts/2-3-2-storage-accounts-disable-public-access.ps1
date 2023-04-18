param(
    [Parameter(Mandatory=$True)][string]$TeamName
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$StorageAccountNamePrefix = "st${TeamName}${Environment}"
$StorageAccountNames = @("${StorageAccountNamePrefix}eu", "${StorageAccountNamePrefix}us", "stshared${TeamName}${Environment}")

foreach ($StorageAccountName in $StorageAccountNames) {
    Write-Output "`nDisabling public access to storage account ${StorageAccountName}..."
    # https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update

    az resource update `
        --resource-group $ResourceGroupName `
        --name $StorageAccountName `
        --resource-type "Microsoft.Storage/storageAccounts" `
        --set properties.publicNetworkAccess=Disabled
}
