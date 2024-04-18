param(
    [Parameter(Mandatory=$True)][string]$SubnetName,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$AddressPrefixes,
    [Parameter(Mandatory=$True)][string]$VnetName,
    [string]$AdditionalArguments = ""
)

# Note that the subnet names are fixed for some resources:
# - Bastion -> AzureBastionSubnet
# - Firewall -> AzureFirewallSubnet

Write-Output "`nCreating subnet ${SubnetName} with address prefixes ${AddressPrefixes} in virtual network ${VnetName}..."
# https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-create()

$Command = "az network vnet subnet create --name ${SubnetName} --resource-group ${ResourceGroupName} --vnet-name ${VnetName} --address-prefixes ${AddressPrefixes} --private-endpoint-network-policies Disabled --private-link-service-network-policies Disabled ${AdditionalArguments}"
Invoke-Expression $Command
