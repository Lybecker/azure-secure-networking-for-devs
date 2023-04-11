param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "northeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"

$VnetNameEu = "vnet-${TeamName}-${Environment}-${PrimaryLocation}"
$VnetNameUs = "vnet-${TeamName}-${Environment}-${SecondaryLocation}"
$VnetNameShared = "vnet-${TeamName}-${Environment}-${SharedLocation}"

Write-Output "`nPeering virtual networks to using the hub and spoke model..."

.\4-1-vnet-peerings.ps1 -ResourceGroupName $ResourceGroupName -VnetName1 $VnetNameShared -VnetName2 $VnetNameEu
.\4-1-vnet-peerings.ps1 -ResourceGroupName $ResourceGroupName -VnetName1 $VnetNameShared -VnetName2 $VnetNameUs

# TODO: Routing
