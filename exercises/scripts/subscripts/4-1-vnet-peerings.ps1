param(
    [Parameter(Mandatory=$True)][string]$ResourceGroupName1,
    [Parameter(Mandatory=$True)][string]$VnetName1,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName2,
    [Parameter(Mandatory=$True)][string]$VnetName2
)

Write-Output "`nPeering virtual networks ${VnetName1} <-> ${VnetName2}..."

$VnetResourceId1 = (az network vnet show --resource-group $ResourceGroupName1 --name $VnetName1 | ConvertFrom-Json).id
$VnetResourceId2 = (az network vnet show --resource-group $ResourceGroupName2 --name $VnetName2 | ConvertFrom-Json).id

# https://learn.microsoft.com/cli/azure/network/vnet/peering?view=azure-cli-latest#az-network-vnet-peering-create

az network vnet peering create `
    --name "peer-${VnetName1}-${VnetName2}" `
    --resource-group $ResourceGroupName1 `
    --vnet-name $VnetName1 `
    --remote-vnet $VnetResourceId2 `
    --allow-vnet-access

az network vnet peering create `
    --name "peer-${VnetName2}-${VnetName1}" `
    --resource-group $ResourceGroupName2 `
    --vnet-name $VnetName2 `
    --remote-vnet $VnetResourceId1 `
    --allow-vnet-access
