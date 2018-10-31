# VPC Third Parties

There are two modules within this folder and you will need to use both of them if you wish to set up a new VPC in the aw-third-parties account.  

## vpc-customer-gateway
Builds out a customer gateway

## vpc-with-igw-vpn
Builds out: -
* VPC 
* 4 Subnets (you will need to edit this dependent on the CIDR ranges you wish to use for your subnets)
* Private and Public Route Tables
* VPN Connection to the Palo in the Infrastructure Team account
* Internet Gateway

The reason for this is that only one customer gateway is needed in any one AWS account, so therefore it is not possible to set up the customer gateway element within the main vpc-with-igw-vpn module.

