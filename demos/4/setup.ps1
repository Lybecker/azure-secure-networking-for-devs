$location = "swedencentral"

Write-Output "Creating resource group rg-corpwebsite-dev-${location}"
az group create `
    --name rg-corpwebsite-dev-${location}  `
    --location $location

Write-Output "Creating virtual network vnet-corpwebsite-dev-${location}"
az network vnet create `
    --name vnet-corpwebsite-dev-${location} `
    --resource-group rg-corpwebsite-dev-${location} `
    --location $location `
    --address-prefix 10.0.0.0/16 `
    --subnet-name snet-corpwebsite-dev-${location} `
    --subnet-prefix 10.0.0.0/24 `

az network vnet subnet update `
    --name snet-corpwebsite-dev-${location} `
    --resource-group rg-corpwebsite-dev-${location} `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --disable-private-endpoint-network-policies false `
    --disable-private-endpoint-network-policies false

Write-Output "Creating virtual network vnet-hub-dev-${location}"
az network vnet create `
    --name vnet-hub-dev-${location} `
    --resource-group rg-corpwebsite-dev-${location} `
    --location $location `
    --address-prefix 10.1.0.0/16 `
    --subnet-name snet-hub-dev-${location} `
    --subnet-prefix 10.1.0.0/24

Write-Output "Peering vnet-corpwebsite-dev-${location} with vnet-hub-dev-${location}"
az network vnet peering create `
    --name peer-corpwebsite-hub `
    --resource-group rg-corpwebsite-dev-${location} `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --remote-vnet vnet-hub-dev-${location} `
    --allow-vnet-access

az network vnet peering create `
    --name peer-hub-corpwebsite `
    --resource-group rg-corpwebsite-dev-${location} `
    --vnet-name vnet-hub-dev-${location} `
    --remote-vnet vnet-corpwebsite-dev-${location} `
    --allow-vnet-access

Write-Output "Creating (managed SQL) database"
az sql server create `
    --name sql-corpwebsite-dev-${location} `
    --resource-group rg-corpwebsite-dev-${location} `
    --location $location `
    --admin-user sqladmin `
    --admin-password "LifeIsComplexSoShouldYourP@asswordBerb46w35b"

Write-Output "Creating private endpoint for database"
$id=$(az sql server list --resource-group rg-corpwebsite-dev-${location} --query '[].[id]' --output tsv)

az network private-endpoint create `
    --name pep-sql-corpwebsite `
    --resource-group rg-corpwebsite-dev-${location} `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --subnet snet-corpwebsite-dev-${location} `
    --private-connection-resource-id ${id} `
    --group-ids sqlServer `
    --connection-name pl-sql-corpwebsite

Write-Output "Configuring private DNS zone for database"
az network private-dns zone create `
    --resource-group rg-corpwebsite-dev-${location} `
    --name "privatelink.database.windows.net"

az network private-dns link vnet create `
    --resource-group rg-corpwebsite-dev-${location} `
    --zone-name "privatelink.database.windows.net" `
    --name dnsl-sql `
    --virtual-network vnet-corpwebsite-dev-${location} `
    --registration-enabled false

az network private-endpoint dns-zone-group create `
    --resource-group rg-corpwebsite-dev-${location} `
    --endpoint-name pep-sql-corpwebsite `
    --name zone-sql `
    --private-dns-zone "privatelink.database.windows.net" `
    --zone-name sql

Write-Output "Creating VM with public IP to act as a web server"
az vm create `
    --name vm-web-dev `
    --resource-group rg-corpwebsite-dev-${location} `
    --image Ubuntu2204 `
    --size Standard_B2s `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --subnet snet-corpwebsite-dev-${location} `
    --public-ip-sku Standard `
    --admin-username azureuser `
    --generate-ssh-keys

Write-Output "Login to the VM via RDP and verify you can reach the database via Powershell command:"
Write-Output "Test-NetConnection -ComputerName 'sql-corpwebsite-dev-${location}.database.windows.net' -Port 1433" 




create subnet AzureFirewallSubnet
Create FW with policy and public IP
Route table - associate to subnet + add route to