# Routes & network security demo

Run the [setup.ps1](setup.ps1) script, which creates 

- two virtual peered networks (Corp website and Hub)
- a virtual machine that acts as a web server in the Corp website virtual network. The virtual machine has public RDP access for demo purposes.
- Azure SQL with private link in the Corp website virtual network

All demos are in the Azure portal.

## System routes

Navigate to the Virtual Machine -> Networking -> Nic -> Effective routes and show the system routes.

| Source | Address Prefixes | Next hop type | Description |
|---|---|---|---|
| Default | 10.0.0.0/16 | Virtual network | Routing within the Corp website virtual network |
| Default | 10.1.0.0/16 | VNet peering | Routing to the Hub virtual network |
| Default | 0.0.0.0/0 | Internet | 0.0.0.0/0 is a catch all rule, so if none of the more specific rules apply, route to the Internet |
| Default | 10.0.0.8/0 | None | An example of a reserved address space, where all traffic gets dropped |

Azure automatically adds routes to the system route table when you create a virtual network, VPN gateway, or virtual network peering. Only when you want to change the default behavior, you need to add custom routes.

## Network security with NSG nad ASG

1. Create ASG asg-web-role and assign it to the nic of the web server/VM
1. Create ASG asg-db-role and assign in the the (SQL -> Networking -> Private access -> pep-sql-corpwebsite -> Application security groups)
1. Create NSG nsg-corpwebsite-dev-swedencentral and associate with subnet snet-corpwebsite-dev-swedencentral. Because the AllowVNetInBound default security rule allows all communication between resources in the same virtual network, this rule is needed to deny traffic from all resources.
    - Create rule Deny-Database-All
    - with priority 120
    - deny all traffic to asg-db-role
1. Show it is not possible to access the database from the web server via RDP

    `Test-NetConnection -ComputerName 'sql-corpwebsite-dev-swedencentral.database.windows.net' -Port 1433`
1. Create rule Allow-Database-BusinessLogic
    - with priority 110
    - allow traffic from asg-web-role to asg-db-role
1. Show it is now possible to access the database from the web server via RDP

    `Test-NetConnection -ComputerName 'sql-corpwebsite-dev-swedencentral.database.windows.net' -Port 1433`
