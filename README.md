# Azure Secure Networking for Developers

This content is designed for developers who want to learn how to use Azure networking services to secure their applications. It is not meant to make you an expert in Azure networking, but to give you enough knowledge to create secure network designs and discuss and collaborate with confidence with network administrators.

It is designed as an instructor lead course, so you can discuss best practices, pros and cons while guiding guidance along the way.

The exercises are designed to be completed in order and the narrative for the work you are doing is in the story below.

## Story

The Company has created an internal web application for managing employee benefits that is exclusively used by their HR department. However, the data stored within the system is subject to privacy regulations and needs to be kept regionally sensitive. Therefore, The Company is planning to deploy two independent applications: one for the European region and the other for the US region. Each application will contain its respective dataset and will not be allowed to cross regions. Nevertheless, a shared read-only control dataset is utilized to manage certain basic functionalities of the application, which The Company prefers to store in a single location. Since the shared data is accessed infrequently, The Company has decided that it does not need to be in the same region. The Company's HR team must be able to access the service within their internal network. However, their internal IT department is currently overloaded with work, and it will take some time for them to set up a site-to-site VPN or an ExpressRoute. Instead they have proposed that we setup a secure Remote Access for HR teams. The webapp needs to be periodically updated, and customer will use automated GitHub Actions to deploy the code from the repository.

The Company has implemented an initial version of the application as a test environment in two resource groups on Azure. Currently, the application is accessible to the public internet without any restrictions, and they are seeking our assistance in securing it from a networking standpoint.

## Exercises

Before starting you need to have an Azure subscription and setup the [prerequisites](./exercises/instructions/0-prerequisites.md).

1. [Virtual networks and subnets](./exercises/instructions/1-vnets.md)
1. [Private networks](./exercises/instructions/2-private-network.md)
1. [Gaining access to secured resources](./exercises/instructions/3-bastion.md)
1. [Virtual network peering](./exercises/instructions/4-vnet-peerings.md)
1. [Firewall and routing](./exercises/instructions/5-firewall-and-routing.md)
1. [Network security group](./exercises/instructions/6-network-and-application-security.md)
1. [Public access](./exercises/instructions/7-public-access.md)

## Instructor notes

The PowerPoint slides are accompanied by [demos](./demos/) with setup script used to help you demonstrate some of the concepts. The demos are not meant to be used as exercises, but to help you demonstrate the concepts.