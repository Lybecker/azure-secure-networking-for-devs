#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$Environment = "dev"

$ResourceGroupNameHub = "rg-hub-${TeamName}-${Environment}"

.\subscripts\2-1-subnet.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "database" "10.0.5.0/25"
.\subscripts\4-2-1-network-security-group.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "database"
.\subscripts\4-2-2-network-security-group-rule.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "database" "100" "Allow" "Inbound" "Tcp" "1433"
.\subscripts\4-3-network-interface.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "database"
.\subscripts\4-4-virtual-machine.ps1 $TeamName $EuLocation "rg-${TeamName}-${Environment}-eu" "database"

.\subscripts\2-1-subnet.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "database" "10.0.9.0/25"
.\subscripts\4-2-1-network-security-group.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "database"
.\subscripts\4-2-2-network-security-group-rule.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "database" "100" "Allow" "Inbound" "Tcp" "1433"
.\subscripts\4-3-network-interface.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "database"
.\subscripts\4-4-virtual-machine.ps1 $TeamName $UsLocation "rg-${TeamName}-${Environment}-us" "database"