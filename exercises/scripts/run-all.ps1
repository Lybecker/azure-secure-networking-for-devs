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

.\1-vnets.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\2-private-network.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\3-bastion-jumpbox.ps1 -TeamName $TeamName -Location $HubLocation
.\4-vnet-peerings.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
.\5-firewall.ps1 -TeamName $TeamName -HubLocation $HubLocation
.\6-network-security-groups.ps1 -TeamName $TeamName -EuLocation $EuLocation -UsLocation $UsLocation -HubLocation $HubLocation
