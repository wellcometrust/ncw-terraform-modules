variable "db_name" {}

variable "db_engine" {}

variable "db_engine_version" {}

variable "db_instance_class" {}

# To use the username and passord for now do this by means of a terraform.tfvars file.  README.md will explain this in greater detail
variable "db_username" {}

variable "db_password" {}

variable "vpc_security_group_ids" {}

variable "back_up_retention_period" {}

variable "allocated_storage" {}

variable "storage_type" {}
variable "subnet_group_name" {}
variable "instance_owner" {}
variable "instance_managed" {}
variable "instance_environment" {}
variable "cost_centre" {}

variable "subnet_ids" {}

variable "db_licence_model" {}

variable "Name" {}
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