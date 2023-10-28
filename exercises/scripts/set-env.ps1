#!/usr/bin/env pwsh

param(
    [string]$TeamName = "newteam",
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus",
    [string]$HubLocation = "swedencentral"
)

$env:TEAM_NAME = $TeamName
$env:HUB_LOCATION = $HubLocation
$env:EU_LOCATION = $EuLocation
$env:US_LOCATION = $UsLocation

Write-Output "Config set:`n  - Team name: ${env:TEAM_NAME}`n  - Hub location: ${env:HUB_LOCATION}`n  - EU location: ${env:EU_LOCATION}`n  - US location: ${env:US_LOCATION}`n"
