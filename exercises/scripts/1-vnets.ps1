param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "swedencentral"
)

.\1-1-vnet.ps1 $TeamName $SharedLocation "10.0.0"
.\1-1-vnet.ps1 $TeamName $PrimaryLocation "10.0.4"
.\1-1-vnet.ps1 $TeamName $SecondaryLocation "10.0.8"
