param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [Parameter(Mandatory=$True)][string]$Location,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$SubnetId,  # Used in the name to identify the purpose e.g., "shared"
    [string]$AdditionalArguments = ""
)

$Environment = "dev"
$VnetName = "vnet-${TeamName}-${Environment}-${Location}"
$SubnetName = "snet-${SubnetId}-${TeamName}-${Environment}-${Location}"
$NicName = "nic-${SubnetId}-${TeamName}-${Environment}-${Location}"
$NsgName = "nsg-${SubnetId}-${TeamName}-${Environment}-${Location}"

Write-Output "`nCreating nic ${NicName} attached with NSG ${NsgName}..."
# https://learn.microsoft.com/en-gb/cli/azure/network/nic?view=azure-cli-latest#az-network-nic-create()

$Command = "az network nic create --name ${NicName} --resource-group ${ResourceGroupName} --location ${Location} --vnet-name ${VnetName} --subnet ${SubnetName} --network-security-group ${NsgName}"
Invoke-Expression $Command
