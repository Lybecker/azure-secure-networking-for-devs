#Example values

# VnetName                = VNet1 
# ResourceGroup           = TestRG1 
# Location                = eastus 
# AddressSpace            = 10.1.0.0/16 
# SubnetName              = Frontend
# Subnet                  = 10.1.0.0/24 
# GatewaySubnet           = 10.1.255.0/27 
# LocalNetworkGatewayName = Site1
# LNG Public IP           = <On-premises VPN device IP address>
# LocalAddrPrefix1        = 10.0.0.0/24
# LocalAddrPrefix2        = 20.0.0.0/24   
# GatewayName             = VNet1GW 
# PublicIP                = VNet1GWIP 
# VPNType                 = RouteBased 
# GatewayType             = Vpn 
# ConnectionName          = VNet1toSite2

export location="eastus"
export rg_name="s2pvpnrg"
export vnet_name="vnet"
export prefix="10.1.0.0/16"
export subnet_name="snet1"
export subnet_prefix="10.1.0.0/24"
export gateway_subnet_prefix="10.1.255.0/27"
export public_ip_name="vnetgwip"
export gw_sku="VpnGw1"
export gw_type="Vpn"
export vpn_gw_name="vnet01gw"
export admin_username="adminUser"
export admin_password="adminPassword!@#11"

# Create a resource group.
az group create --name $rg_name --location $location

# Create the virtual network and with default subnet.
az network vnet create --name $vnet_name \
                        --resource-group $rg_name \
                        --address-prefix $prefix \
                        --location $location \
                        --subnet-name $subnet_name \
                        --subnet-prefix $subnet_prefix

# Create the gateway subnet.
az network vnet subnet create --address-prefix $gateway_subnet_prefix \
                                --name GatewaySubnet \
                                --resource-group $rg_name \
                                --vnet-name $vnet_name

# Create the public IP address.
az network public-ip create --resource-group $rg_name \
                            --name $public_ip_name \
                            --allocation-method Dynamic

# Create the VPN gateway.
az network vnet-gateway create --resource-group $rg_name \
                                --name $vpn_gw_name \
                                --public-ip-address $public_ip_name \
                                --vnet $vnet_name \
                                --gateway-type $gw_type \
                                --sku $gw_sku \
                                --vpn-type RouteBased

# Verify that gateway is created successfully.
az network vnet-gateway show --resource-group $rg_name --name $vpn_gw_name -o table

# Retrieve the public IP address for the VPN gateway.
az network public-ip show --name $public_ip_name --resource-group $rg_name 

# Once VPN gateway finishes creating, we need to add the VPN client address pool.
az network vnet-gateway update --resource-group $rg_name \
                                --name $vpn_gw_name \
                                --address-prefixes 172.16.200.0/26 \
                                --client-protocol SSTP

# Deploy sample virtual machine to test VPN connection
az deployment group create --resource-group $rg_name \
                            --template-file ./raw-material/bicep/vm.bicep \
                            --parameters adminUsername=$admin_username \
                                        adminPassword=$admin_password \
                                        virtualNetworkName=$vnet_name \
                                        subnetName=$subnet_name

# Generate a self-signed root certificate
openssl genpkey -algorithm RSA -out root.key
openssl req -new -key root.key -out root.csr -subj "/CN=Root CA"
openssl x509 -req -in root.csr -signkey root.key -out root.crt

# Generate a self-signed client certificate using the root certificate
openssl genpkey -algorithm RSA -out client.key
openssl req -new -key client.key -out client.csr -subj "/CN=Client"
openssl x509 -req -in client.csr -CA root.crt -CAkey root.key -CAcreateserial -out client.crt

# Convert the certificates to DER format and copy all certificate files to the host machine
openssl x509 -in root.crt -outform der -out root.cer
openssl x509 -in client.crt -outform der -out client.cer

# Convert the certificates to Base64 format and copy all certificate files to the host machine
openssl x509 -inform der -in root.cer -out root_base64.cer
openssl x509 -inform der -in client.cer -out client_base64.cer

# Convert the certificates to PFX format and copy all certificate files to the host machine
openssl x509 -in root.cer -inform DER -out root.pem -outform PEM
openssl pkcs12 -export -out root.p12 -inkey root.key -in root.pem

# Convert the certificates to PFX format and copy all certificate files to the host machine
openssl x509 -in client.cer -inform DER -out client.pem -outform PEM
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.pem

# Add Public certificate to VPN gateway to connect
export certificate_path="${pwd}/root.cer"
az network vnet-gateway root-cert create --resource-group $rg_name -n P2SRootCert --gateway-name $vpn_gw_name --public-cert-data $certificate_path

# Generate VPN Client to install
az network vnet-gateway vpn-client generate --resource-group $rg_name --name $vpn_gw_name --processor-architecture Amd64

# To test the VPN, you need to install VPN Client to your OS to connect to VPN Gateway
# For macOS and iOS -> https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-vpn-client-cert-mac
# For Windows -> https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-vpn-client-cert-windows#configure-the-vpn-client-profile