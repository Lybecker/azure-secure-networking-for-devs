#!/usr/bin/env pwsh

param(
    [string]$TeamName = "newteam",
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus2",
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

$envVarsToStore = @{
    TEAM_NAME = $TeamName
    HUB_LOCATION = $HubLocation
    EU_LOCATION = $EuLocation
    US_LOCATION = $UsLocation
}

# Set environment variables in the current session using a for loop
foreach ($key in $envVarsToStore.Keys) {
    Set-Item -Path "Env:$key" -Value $envVarsToStore[$key]
}

Write-Output "Config set successfully:`n  - Team name: $($envVarsToStore.TEAM_NAME)`n  - Hub location: $($envVarsToStore.HUB_LOCATION)`n  - EU location: $($envVarsToStore.EU_LOCATION)`n  - US location: $($envVarsToStore.US_LOCATION)`n"

.\store-env-vars.ps1 -EnvVarsToStore $envVarsToStore