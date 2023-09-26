param(
    [Parameter(Mandatory=$True)][string]$TeamName
)

$Environment = "dev"
$ResourceGroupNames = @("rg-hub-${TeamName}-${Environment}", "rg-${TeamName}-${Environment}-eu", "rg-${TeamName}-${Environment}-us")
$StorageAccountNamePrefix = "st${TeamName}${Environment}"
$StorageAccountNames = @("sthub${TeamName}${Environment}", "${StorageAccountNamePrefix}eu", "${StorageAccountNamePrefix}us")

for ($i = 0; $i -lt 3; $i++) {
    $StorageAccountName = $StorageAccountNames[$i]
    $ResourceGroupName = $ResourceGroupNames[$i]

    Write-Output "`nDisabling public access to storage account ${StorageAccountName}..."
    # https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update

    az resource update `
        --resource-group $ResourceGroupName `
        --name $StorageAccountName `
        --resource-type "Microsoft.Storage/storageAccounts" `
        --set properties.publicNetworkAccess=Disabled
}
