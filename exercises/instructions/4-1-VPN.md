# Make it corporate

> If you haven't already, make sure you've at least peered your networks:
>
> ```ps1
> .\3-vnet-peerings.ps1
> ```

## VPN

Having a virtual machine jumpbox is a neat-o way to access your now locked down network, but that's not how the CORPORATE would do it. We have to introduce something that was all the rage back in the 2000s, a corporate VPN to your network.

Now it may sound scary, but Azure makes it super simple. We just create something called a Virtual Network Gateway of a VPN type, create couple of certificates and tie it all together. Let's get started.

1. Create a public IP address in the **hub location**. This  will be used as a fixed public IP address for your VPN Gateway.
1. Create a subnet for VNET Gateway in the VNET in the **hub location** - the name should be `GatewaySubnet`, and we'll give it enough space so make it `10.0.1.0/24`
1. Create a [Virtual Network Gateway](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal#creategw) resource in the **hub location** using the newly created public IP address and add it to the virtual network
    1. Set Gateway type to VPN
    1. Set SKU to VpnGw1 (that will lower our costs)
    1. Disable active-active mode (we don't need reduncuncy here)
1. Next, we need to create some certificates. You should do these steps on your local machine, as the certificates will be entered into your local certificate store.
    - Create a self-signed root certificate. This certificate we will upload to Azure.

    ```ps1
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
    ```

    - Create a client certificate based on the root certificate. The client certificates can then be distributed to all client computers that need to connect to the VPN:

    ```ps1
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
    ```

    - Now you can either use Windows Certificate Manager to export the certificate as a Base64 or you can do it with this script. This will export the root certificate into a file called 'P2SRootCert.cer' in the same folder where you are running the script.

    ```ps1
    $Base64Certificate = @"
    -----BEGIN CERTIFICATE-----
    $([Convert]::ToBase64String($Cert.Export('Cert'), [System.Base64FormattingOptions]::InsertLineBreaks)))
    -----END CERTIFICATE-----
    "@
    Set-Content -Path "P2SRootCert.cer" -Value $Base64Certificate
    ```

1. Open the newly created 'P2SRootCert.cer' in a Notepad and copy the certificate contents between BEGIN CERTIFICATE and END CERTIFICATE lines.
1. Now that we have the certificate contents and the VPN Gateway is created, we can configure it:
    1. Navigate to VNET Gateway in Portal, click on Point-to-site configuration
    1. Set the address pool to '172.16.200.0/26', these will be the addresses given to the client machines.
    1. Set the Tunnel type to 'SSTP'
    1. Under Authentication type, select 'Azure certificate'
    1. Under Root Certificates add a new value, with:
        - Name: 'P2RootCert'
        - Public Certificate Data: contents that you copied from 'P2RootCert.cer' file
    1. Save the changes.
    1. Now you are ready to download the VPN Client. Press the button on the page and it will download a ZIP package with all generated clients.
1. Run the approriate client to install it on your machine. For Windows, you can run the one in WindowsAmd64. Accept the dialogs, and once it is installed, you should see a new VPN connection in your VPN settings.

> Naming recommendations:
>
> - Public IP address: `pip-gatway-{team name}-dev`
> - VNET Gateway: `vpn-gw-{team name}-dev`

## Status check

Click on the Connect on your newly created VPN connection and verify that you can establish a connection. Once the connection is establish, you can try to ping any resources that should be on private network, for example storage or web apps. The ping response should give you an IP in 10.*.*.* range.

## Tips and tricks

### Learning resources

- [Configure P2S VPN Gateway connections with certificate authentication](httpshttps://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal#creategw)

### Relevant Azure CLI commands

- [az network public-ip create](https://learn.microsoft.com/en-us/cli/azure/network/public-ip?view=azure-cli-latest#az-network-public-ip-create)
- [az network vnet-gateway create](https://learn.microsoft.com/en-us/cli/azure/network/vnet-gateway?view=azure-cli-latest#az-network-vnet-gateway-create)
- [az network vnet-gateway update](https://learn.microsoft.com/en-us/cli/azure/network/vnet-gateway?view=azure-cli-latest#az-network-vnet-gateway-update)
- [az network vnet-gateway root-cert create](https://learn.microsoft.com/en-us/cli/azure/network/vnet-gateway/root-cert?view=azure-cli-latest#az-network-vnet-gateway-root-cert-create)
- [az network vnet-gateway vpn-client generate](https://learn.microsoft.com/en-us/cli/azure/network/vnet-gateway/vpn-client?view=azure-cli-latest#az-network-vnet-gateway-vpn-client-generate)

## Back to the overview

[Azure Secure Networking for Developers - start page](/README.md)
