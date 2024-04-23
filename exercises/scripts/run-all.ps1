#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION,
    [string]$JumpboxAdminUsername = "jumpboxuser",
    [string]$JumpboxAdminPassword = "JumpboxPassword123!"
)

.\0-prerequisites.ps1 `
    -TeamName $TeamName `
    -EuLocation $EuLocation `
    -UsLocation $UsLocation `
    -HubLocation $HubLocation `
    -JumpboxAdminUsername $JumpboxAdminUsername `
    -JumpboxAdminPassword $JumpboxAdminPassword

.\1-vnets.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation
.\2-private-network.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\3-vnet-peerings.ps1 -TeamName $TeamName
.\4-bastion-jumpbox.ps1 -TeamName $TeamName -Location $HubLocation
.\5-firewall.ps1 -TeamName $TeamName -HubLocation $HubLocation
.\6-asgs-nsgs.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
