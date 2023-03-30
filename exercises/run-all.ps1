param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "northeurope"
)

.\0-prerequisites.ps1 -TeamName $TeamName -PrimaryLocation $PrimaryLocation -SecondaryLocation $SecondaryLocation -SharedLocation $SharedLocation
.\1-vnets.ps1 -TeamName $TeamName -PrimaryLocation $PrimaryLocation -SecondaryLocation $SecondaryLocation -SharedLocation $SharedLocation
.\2-private-network.ps1 -TeamName $TeamName -PrimaryLocation $PrimaryLocation -SecondaryLocation $SecondaryLocation -SharedLocation $SharedLocation
