#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$EuLocation = $env:EU_LOCATION,
    [string]$UsLocation = $env:US_LOCATION,
    [string]$HubLocation = $env:HUB_LOCATION,
    [string]$Environment = "dev"
)

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

$env:ASNFD_RESOURCE_GROUP_NAME_EU = "rg-${TeamName}-${Environment}-eu"
$env:ASNFD_RESOURCE_GROUP_NAME_US = "rg-${TeamName}-${Environment}-us"
$env:ASNFD_RESOURCE_GROUP_NAME_HUB = "rg-${TeamName}-${Environment}-hub"

$env:ASNFD_STORAGE_ACCOUNT_NAME_EU = "st${TeamName}${Environment}eu"
$env:ASNFD_STORAGE_ACCOUNT_NAME_US = "st${TeamName}${Environment}us"
$env:ASNFD_STORAGE_ACCOUNT_NAME_HUB = "st${TeamName}${Environment}hub"

$AppServicePlanNamePrefix = "asp-${TeamName}-${Environment}"
$env:ASNFD_APP_SERVICE_PLAN_NAME_EU = "${AppServicePlanNamePrefix}-eu"
$env:ASNFD_APP_SERVICE_PLAN_NAME_US = "${AppServicePlanNamePrefix}-us"

$AppServiceNamePrefix = "app-${TeamName}-${Environment}"
$env:ASNFD_APP_SERVICE_NAME_EU = "${AppServiceNamePrefix}-eu"
$env:ASNFD_APP_SERVICE_NAME_US = "${AppServiceNamePrefix}-us"

$env:ASNFD_VNET_NAME_EU = "vnet-${TeamName}-${Environment}-${EuLocation}"
$env:ASNFD_VNET_NAME_US = "vnet-${TeamName}-${Environment}-${UsLocation}"
$env:ASNFD_VNET_NAME_HUB = "vnet-${TeamName}-${Environment}-${HubLocation}"

$env:ASNFD_DEFAULT_SNET_NAME_EU = "snet-default-${TeamName}-${Environment}-${EuLocation}"
$env:ASNFD_DEFAULT_SNET_NAME_US = "snet-default-${TeamName}-${Environment}-${UsLocation}"
$env:ASNFD_DEFAULT_SNET_NAME_HUB = "snet-default-${TeamName}-${Environment}-${HubLocation}"
$env:ASNFD_APPS_SNET_NAME_EU = "snet-apps-${TeamName}-${Environment}-${EuLocation}"
$env:ASNFD_APPS_SNET_NAME_US = "snet-apps-${TeamName}-${Environment}-${UsLocation}"

$env:ASNFD_JUMPBOX_NSG_NAME = "nsg-jumpbox-${TeamName}-${Environment}-hub"

Write-Output "`nResource names set"
