param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "swedencentral"
)

.\2-1-subnet.ps1 $TeamName $SharedLocation "shared" "10.0.0.0/26" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"

.\2-1-subnet.ps1 $TeamName $PrimaryLocation "shared" "10.0.4.0/25" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"
.\2-1-subnet.ps1 $TeamName $PrimaryLocation "apps" "10.0.4.128/25" "--delegations Microsoft.Web/serverFarms"

.\2-1-subnet.ps1 $TeamName $SecondaryLocation "shared" "10.0.8.0/25" "--service-endpoints Microsoft.KeyVault Microsoft.Storage"
.\2-1-subnet.ps1 $TeamName $SecondaryLocation "apps" "10.0.8.128/25" "--delegations Microsoft.Web/serverFarms"

.\2-2-private-dns-zones.ps1 $TeamName

.\2-3-private-endpoints.ps1 $TeamName $PrimaryLocation $SecondaryLocation $SharedLocation

.\2-4-web-app-vnet-integration.ps1 $TeamName $PrimaryLocation $SecondaryLocation $SharedLocation
