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
$NsgName = "nsg-${SubnetId}-${TeamName}-${Environment}-${Location}"
$RuleName = "rule-${InboundPort}-${SubnetId}-${TeamName}-${Environment}-${Location}"

Write-Output "`nCreating nsg ${NsgName} with rule on ${InboundPort}..."
# https://learn.microsoft.com/en-gb/cli/azure/network/nsg?view=azure-cli-latest#az-network-nsg-create()

$Command = "az network nsg create --name ${NsgName} --resource-group ${ResourceGroupName} --location ${Location}"
Invoke-Expression $Command

