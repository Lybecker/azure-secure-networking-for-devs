export location="eastus"
export rg_name="asg-nsg-dev"
export vnet_name="vnet"
export prefix="10.1.0.0/16"
export subnet_web_name="web-snet"
export subnet_web_prefix="10.1.1.0/24"
export subnet_db_name="db-snet"
export subnet_db_prefix="10.1.2.0/24"
export subnet_bastion_name="AzureBastionSubnet"
export subnet_bastion_prefix="10.1.3.0/26"
export nic_web_name="nic_web"
export nic_db_name="nic_db"
export nsg_all_web_name="nsg_web"
export nsg_all_db_name="nsg_db"
export nsg_rule_all_web_traffic_rule_name="AllowWebTraffic"
export nsg_rule_all_web_traffic_port=80
export nsg_rule_all_web_traffic_rule_all_outbound_name="AllowOutbound"
export nsg_rule_all_db_traffic_rule_name="AllowDBTraffic"
export nsg_rule_all_db_traffic_port=1433
export asg_name="web-asg"
export server_web_name="webserverdev"
export server_db_name="dbserverdev"

# Create a vnet
az network vnet create --name $vnet_name \
                        --resource-group $rg_name \
                        --address-prefix $prefix \
                        --location $location
# Create subnets
az network vnet subnet create --name $subnet_web_name \
                                --resource-group $rg_name \
                                --vnet-name $vnet_name \
                                --address-prefixes $subnet_web_prefix

# Create subnets
az network vnet subnet create --name $subnet_db_name \
                                --resource-group $rg_name \
                                --vnet-name $vnet_name \
                                --address-prefixes $subnet_db_prefix

# Create a subnet for Azure Bastion
az network vnet subnet create --name $subnet_bastion_name \
                                --resource-group $rg_name \
                                --vnet-name $vnet_name \
                                --address-prefix $subnet_bastion_prefix

# Create an NSG
az network nsg create --name $nsg_all_web_name \
                        --resource-group $rg_name \
                        --location $location \

# Create an NSG
az network nsg create --name $nsg_all_db_name \
                        --resource-group $rg_name \
                        --location $location \

# Create NSG rules for web traffic
az network nsg rule create --name $nsg_rule_all_db_traffic_rule_name \
                            --nsg-name $nsg_all_db_name \
                            --priority 100 \
                            --resource-group $rg_name \
                            --access Allow \
                            --direction Inbound \
                            --protocol Tcp \
                            --destination-port-range $nsg_rule_all_db_traffic_port

# Create an ASG for web servers
az network asg create --name $asg_name \
                        --resource-group $rg_name \
                        --location $location

az network nsg rule create --name $nsg_rule_all_web_traffic_rule_name \
                            --nsg-name $nsg_all_web_name \
                            --resource-group $rg_name \
                            --priority 200 \
                            --source-address-prefixes Internet \
                            --destination-port-ranges $nsg_rule_all_web_traffic_port \
                            --destination-asgs $asg_name \
                            --access Allow \
                            --protocol Tcp \
                            --description "Allow Internet to Web ASG on ports 80,8080."

#Instead of NIC, we can also assign NSG's to Subnet.
#The benefit of assign to subnet is that all NIC's in that subnet will inherit the NSG.
az network nic create --resource-group $rg_name \
                        --name $nic_web_name \
                        --vnet-name $vnet_name \
                        --subnet $subnet_web_name \
                        --network-security-group $nsg_all_web_name \
                        --application-security-groups $asg_name

az network nic create --resource-group $rg_name \
                        --name $nic_db_name \
                        --vnet-name $vnet_name \
                        --subnet $subnet_db_name \
                        --network-security-group $nsg_all_db_name

# Create a public IP address for the bastion host
az network public-ip create --resource-group $rg_name \
                            --name bastion-ip \
                            --sku Standard \
                            --location $location

# Create a bastion host
az network bastion create --location $location \
                            --name bastion-dev \
                            --public-ip-address bastion-ip \
                            --resource-group $rg_name \
                            --vnet-name $vnet_name

# Create sample virtual machine
az vm create --resource-group $rg_name \
                --name $server_web_name \
                --image Ubuntu2204 \
                --nics $nic_web_name \
                --generate-ssh-keys \
                --verbose  \
                --custom-data cloud-init.txt

# Create sample virtual machine
az vm create --resource-group $rg_name \
                --name $server_db_name \
                --image Ubuntu2204 \
                --nics $nic_db_name \
                --generate-ssh-keys \
                --verbose 

