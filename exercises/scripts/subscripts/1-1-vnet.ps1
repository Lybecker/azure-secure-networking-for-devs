param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "westeurope",
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [string]$IpPrefix = "10.0.0"
)

$VnetName = "vnet-${TeamName}-${Environment}-${Location}"
$AddressPrefixes = "${IpPrefix}.0/22"

Write-Output "`nCreating virtual network `"${VnetName}`" with address prefixes ${AddressPrefixes}..."
# https://learn.microsoft.com/cli/azure/network/vnet?view=azure-cli-latest#az-network-vnet-create()

az network vnet create `
    --name $VnetName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --address-prefixes "${IpPrefix}.0/22"
