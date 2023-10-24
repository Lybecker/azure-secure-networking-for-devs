param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [Parameter(Mandatory=$True)][string]$Location,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$SubnetId,  # Used in the name to identify the purpose e.g., "shared"
    [Parameter(Mandatory=$True)][string]$RulePriority,
    [Parameter(Mandatory=$True)][string]$Access,
    [Parameter(Mandatory=$True)][string]$Direction,
    [Parameter(Mandatory=$True)][string]$Protocol,
    [Parameter(Mandatory=$True)][string]$InboundPort,
    [string]$AdditionalArguments = ""
)

$Environment = "dev"
$VnetName = "vnet-${TeamName}-${Environment}-${Location}"
$SubnetName = "snet-${SubnetId}-${TeamName}-${Environment}-${Location}"
$NsgName = "nsg-${SubnetId}-${TeamName}-${Environment}-${Location}"
$RuleName = "rule-${InboundPort}-${SubnetId}-${TeamName}-${Environment}-${Location}"

Write-Output "`nCreating nsg ${NsgName} rule on ${InboundPort}..."
# https://learn.microsoft.com/en-gb/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create()

$Command = "az network nsg rule create --name ${RuleName} --nsg-name ${NsgName} --priority ${RulePriority} --access ${Access} --direction ${Direction} --protocol ${Protocol} --resource-group ${ResourceGroupName} --destination-port-range ${InboundPort}"
Invoke-Expression $Command