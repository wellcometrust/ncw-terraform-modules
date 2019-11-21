# Instance
variable "ami" {}

variable "instance_type" {}
variable "key_pair" {}
variable "subnet_id" {}
variable "disable_api_termination" {}
variable "source_dest_check" {}

variable "vpc_security_group_ids" {
}

# Root device
variable "root_volume_type" {}

variable "root_volume_size" {}

# Instance tagging
variable "Name" {}

variable "Owner" {}
variable "Managed" {}
variable "Environment" {}
variable "Cost" {}
variable "Division" {}
variable "Department" {}
variable "Internal" {}

variable "iam_instance_profile" {}
