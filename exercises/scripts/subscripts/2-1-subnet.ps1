param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [Parameter(Mandatory=$True)][string]$Location,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$SubnetId,  # Used in the name to identify the purpose e.g., "shared"
    [Parameter(Mandatory=$True)][string]$AddressPrefixes,
    [string]$AdditionalArguments = ""
)

$Environment = "dev"
$VnetName = "vnet-${TeamName}-${Environment}-${Location}"

if ($SubnetId.ToLower() -Match "bastion") {
    $SubnetName = "AzureBastionSubnet"
} elseif ($SubnetId.ToLower() -Match "firewall") {
    $SubnetName = "AzureFirewallSubnet"
} else {
    $SubnetName = "snet-${SubnetId}-${TeamName}-${Environment}-${Location}"
}

Write-Output "`nCreating subnet ${SubnetName} with address prefixes ${AddressPrefixes} in virtual network ${VnetName}..."
# https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-create()

$Command = "az network vnet subnet create --name ${SubnetName} --resource-group ${ResourceGroupName} --vnet-name ${VnetName} --address-prefixes ${AddressPrefixes} --disable-private-endpoint-network-policies false --disable-private-link-service-network-policies false ${AdditionalArguments}"
Invoke-Expression $Command
