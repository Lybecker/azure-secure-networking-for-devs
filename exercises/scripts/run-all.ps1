#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION
)

.\0-prerequisites.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\1-vnets.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\2-private-network.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\3-bastion-jumpbox.ps1 -TeamName $TeamName -Location $HubLocation
.\4-vnet-peerings-firewall-and-routing.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
