#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$Location = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

$Environment = "dev"
$ResourceGroupName = "rg-hub-${TeamName}-${Environment}"
$FirewallName = "afw-${TeamName}-${Environment}-${Location}"
$FirewallPublicIpAddressName = "pip-firewall-${TeamName}-${Environment}-${Location}"
$FirewallPublicIpConfigName = "config-${FirewallPublicIpAddressName}"
$VnetName = "vnet-${TeamName}-${Environment}-${Location}"

#.\2-1-subnet.ps1 $TeamName $Location "firewall" "10.0.0.128/26"

Write-Output "`nCreating firewall ${FirewallName}..."

az network firewall create `
    --name $FirewallName `
    --resource-group $ResourceGroupName `
    --location $Location

Write-Output "`nCreating public IP address for firewall..."

az network public-ip create `
    --name $FirewallPublicIpAddressName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --allocation-method static `
    --sku standard

#Write-Output "`nPausing the script to give time for the previous step(s) to take an effect, please wait..."
#Start-Sleep -Seconds 30

Write-Output "`nConfiguring public IP for firewall..."

az network firewall ip-config create `
    --firewall-name $FirewallName `
    --name $FirewallPublicIpConfigName `
    --public-ip-address $FirewallPublicIpAddressName `
    --resource-group $ResourceGroupName `
    --vnet-name $VnetName

Write-Output "`nUpdating firewall..."

az network firewall update `
    --name $FirewallName `
    --resource-group $ResourceGroupName

az network public-ip show `
    --name $FirewallPublicIpAddressName `
    --resource-group $ResourceGroupName

# https://learn.microsoft.com/cli/azure/network/firewall/ip-config?view=azure-cli-latest#az-network-firewall-ip-config-list
$FirewallPrivateIpAddress=(az network firewall ip-config list --resource-group $ResourceGroupName --firewall-name $FirewallName --query "[?name=='${FirewallPublicIpConfigName}'].privateIpAddress" | ConvertFrom-Json)

Write-Output "`nFirewall private IP address: ${FirewallPrivateIpAddress}"
