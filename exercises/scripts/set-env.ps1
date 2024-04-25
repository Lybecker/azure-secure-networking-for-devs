#!/usr/bin/env pwsh

param(
    [string]$TeamName = "newteam",
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus",
    [string]$HubLocation = "swedencentral"
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

if ($TeamName.Length -gt 10) {
    Write-Error "Invalid argument: Team name too long (must be less than 10 characters long)"
    exit 1
}

if ($TeamName -cnotmatch '^[a-z0-9]+$') {
    Write-Error "Invalid argument: Team name is invalid (must be lower case alphanumeric characters)"
    exit 1
}

$env:TEAM_NAME = $TeamName
$env:HUB_LOCATION = $HubLocation
$env:EU_LOCATION = $EuLocation
$env:US_LOCATION = $UsLocation

Write-Output "Config set successfully:`n  - Team name: ${env:TEAM_NAME}`n  - Hub location: ${env:HUB_LOCATION}`n  - EU location: ${env:EU_LOCATION}`n  - US location: ${env:US_LOCATION}`n"
