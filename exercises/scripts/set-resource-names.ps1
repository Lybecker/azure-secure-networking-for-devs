#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION,
    [string]$Environment = "dev"
)

Write-Output "TeamName: $TeamName"
Write-Output "EuLocation: $EuLocation"
Write-Output "UsLocation: $UsLocation"
Write-Output "HubLocation: $HubLocation"
Write-Output "Environment: $Environment"

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

if ($EuLocation.Length -eq 0) {
    Write-Error "Invalid argument: EU location missing"
    exit 1
}

if ($UsLocation.Length -eq 0) {
    Write-Error "Invalid argument: US location missing"
    exit 1
}

if ($HubLocation.Length -eq 0) {
    Write-Error "Invalid argument: Hub location missing"
    exit 1
}

if ($Environment.Length -eq 0) {
    Write-Error "Invalid argument: Environment missing"
    exit 1
}

$AppServiceNamePrefix = "asp-$TeamName-$Environment"
$AppServicePlanNamePrefix = "asp-${TeamName}-${Environment}"

$envVarsToStore = @{
    ASNFD_RESOURCE_GROUP_NAME_EU = "rg-$TeamName-$Environment-eu"
    ASNFD_RESOURCE_GROUP_NAME_US = "rg-${TeamName}-${Environment}-us"
    ASNFD_RESOURCE_GROUP_NAME_HUB = "rg-${TeamName}-${Environment}-hub"
    
    ASNFD_STORAGE_ACCOUNT_NAME_EU = "st${TeamName}${Environment}eu"
    ASNFD_STORAGE_ACCOUNT_NAME_US = "st${TeamName}${Environment}us"
    ASNFD_STORAGE_ACCOUNT_NAME_HUB = "st${TeamName}${Environment}hub"
    
    ASNFD_APP_SERVICE_PLAN_NAME_EU = "${AppServicePlanNamePrefix}-eu"
    ASNFD_APP_SERVICE_PLAN_NAME_US = "${AppServicePlanNamePrefix}-us"

    ASNFD_APP_SERVICE_NAME_EU = "${AppServiceNamePrefix}-eu"
    ASNFD_APP_SERVICE_NAME_US = "${AppServiceNamePrefix}-us"
    
    ASNFD_VNET_NAME_EU = "vnet-${TeamName}-${Environment}-eu"
    ASNFD_VNET_NAME_US = "vnet-${TeamName}-${Environment}-us"
    ASNFD_VNET_NAME_HUB = "vnet-${TeamName}-${Environment}-hub"
    
    ASNFD_DEFAULT_SNET_NAME_EU = "snet-default-${TeamName}-${Environment}-eu"
    ASNFD_DEFAULT_SNET_NAME_US = "snet-default-${TeamName}-${Environment}-us"
    ASNFD_DEFAULT_SNET_NAME_HUB = "snet-default-${TeamName}-${Environment}-hub"
   
   ASNFD_APPS_SNET_NAME_EU = "snet-apps-${TeamName}-${Environment}-eu"
    ASNFD_APPS_SNET_NAME_US = "snet-apps-${TeamName}-${Environment}-us"
    ASNFD_JUMPBOX_NSG_NAME = "nsg-jumpbox-${TeamName}-${Environment}-hub"
}

# Print the environment variables to be stored
foreach ($key in $envVarsToStore.Keys) {
    Write-Output "$key = $($envVarsToStore[$key])"
}

# Set environment variables in the current session using a for loop
foreach ($key in $envVarsToStore.Keys) {
    Set-Item -Path "Env:$key" -Value $envVarsToStore[$key]
}

Write-Output "`nResource names set"

.\store-env-vars.ps1 -EnvVarsToStore $envVarsToStore
