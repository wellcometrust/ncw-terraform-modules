# VPC / Subnet Variables
variable "cidr_block" {}

variable "region" {}

variable "gateway-id" {}
variable "enable_dns_hostnames" {}

variable "enable_classiclink" {}
variable "enable_dns_support" {}

# Tag Variables
variable "vpc_name" {}

variable "vpn-gateway-name" {}
variable "vpn-connection-name" {}

variable "Owner" {}
variable "Cost" {}
variable "Department" {}
variable "Division" {}
variable "Environment" {}
variable "Terraform" {}
variable "Use" {}
variable "Ansible" {}
variable "Internal" {}
variable "BackUps" {}
variable "PatchGroup" {}
