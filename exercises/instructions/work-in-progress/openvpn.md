# Supplementary Information on creating a VPN VM inside Azure Virtual Network

Since we have closed off all public access to most deployed resources. One of the challenges that we faced is how to develop locally. The basic idea is to create a VM inside the Azure Virtual Network that hosts the Azure Cognitive Search service and the Azure Function. This VM will host an OpenVPN server that we can connect to from our local machines. Once connected, we will be able to access all the resources inside the Azure Virtual Network.

## Private networks

- Deploy a VM into the virtual network and open the SSH port and port 1194 (to be used for the OpenVPN server). I have tested this with Ubuntu 22.04 LTS.
- ssh into the VM and run the following commands:
- `curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh`
- `chmod +x openvpn-install.sh`
- `sudo ./openvpn-install.sh` and follow the prompts and use the defaults for everything (when prompted to the machine ip, provide the machine public ip, not the private ip)
- From the host machine (your local machine), copy the client.ovpn file from the VM to your local machine using the following command:
- `scp -i ./id_rsa  azureuser@20.83.167.34:/home/azureuser/Vpfile.ovpn ~/Vpfile.ovpn`
- From the deployed VM, we need to change the DNS server to point to the Azure DNS server. To do that, run the following commands:
- `sudo nano /etc/openvpn/server.conf`
- change dns server line to `push "dhcp-option DNS 168.63.129.16"` and remove existing dns servers
- `sudo systemctl restart openvpn.service`
- `sudo systemctl restart openvpn@server.service`
- From the host machine, install OpenVPN client and connect to the VPN using the `ovpn` file.

## Download OpenVpn Client

1. Download OpenVPN client
2. Add the "ovpn" client from open vpn server to the client
3. Download the RDP file for the jumperbox vm
4. Connect to the jumperbox vm using the RDP file
