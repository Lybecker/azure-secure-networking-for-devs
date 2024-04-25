#!/usr/bin/env pwsh

param(
    [string]$TeamName = $env:TEAM_NAME,
    [string]$HubLocation = $env:HUB_LOCATION
)

if ($TeamName.Length -lt 2) {
    Write-Error "Invalid argument: Team name missing or too short (must be at least 2 characters long)"
    exit 1
}

if ($HubLocation.Length -eq 0) {
    Write-Error "Invalid argument: Hub location missing"
    exit 1
}

$Environment = "dev"

.\set-resource-names.ps1 -TeamName $TeamName -EuLocation $env:EU_LOCATION -UsLocation $env:US_LOCATION -HubLocation $HubLocation -Environment $Environment

$GatewayPublicIpAddressName = "pip-gateway-${TeamName}-${Environment}"
$GatewayName = "vpn-gw-${TeamName}-${Environment}"
$GatewayType = "vpn"
$GatewaySKU = "vpngw1"
$VpnType = "RouteBased"

az network public-ip create `
    --resource-group $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    --name $GatewayPublicIpAddressName `
    --sku Standard `
    --location $HubLocation

.\subscripts\2-1-subnet.ps1 `
    -SubnetName 'GatewaySubnet' `
    -ResourceGroupName $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    -AddressPrefixes "10.0.1.0/24" `
    -VnetName $env:ASNFD_VNET_NAME_HUB

az network vnet-gateway create `
    --resource-group $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    --name $GatewayName `
    --public-ip-address $GatewayPublicIpAddressName `
    --vnet $env:ASNFD_VNET_NAME_HUB `
    --gateway-type $GatewayType `
    --sku $GatewaySKU `
    --vpn-type $VpnType

az network vnet-gateway update `
    --resource-group $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    --name $GatewayName `
    --address-prefixes 172.16.200.0/26 `
    --client-protocol SSTP

$Params = @{
    Type = 'Custom'
    Subject = 'CN=P2SRootCert'
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyUsage = 'CertSign'
    KeyUsageProperty = 'Sign'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
    }
$Cert = New-SelfSignedCertificate @Params

$Params = @{
    Type = 'Custom'
    Subject = 'CN=P2SChildCert'
    DnsName = 'P2SChildCert'
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(18)
    CertStoreLocation = 'Cert:\CurrentUser\My'
    Signer = $Cert
    TextExtension = @(
     '2.5.29.37={text}1.3.6.1.5.5.7.3.2')
}
New-SelfSignedCertificate @Params

$Base64Certificate = @"
-----BEGIN CERTIFICATE-----
$([Convert]::ToBase64String($Cert.Export('Cert'), [System.Base64FormattingOptions]::InsertLineBreaks))
-----END CERTIFICATE-----
"@
Set-Content -Path "P2SRootCert.cer" -Value $Base64Certificate

$CertificatePath = "P2SRootCert.cer"

az network vnet-gateway root-cert create `
    --resource-group $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    -n P2SRootCert `
    --gateway-name $GatewayName `
    --public-cert-data $CertificatePath

az network vnet-gateway vpn-client generate `
    --resource-group $env:ASNFD_RESOURCE_GROUP_NAME_HUB `
    --name $GatewayName `
    --processor-architecture Amd64
