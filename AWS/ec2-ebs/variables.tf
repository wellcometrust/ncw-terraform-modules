# Instance
variable "ami" {}

variable "instance_type" {}
variable "key_pair" {}
variable "subnet_id" {}
variable "associate_public_ip" {}
variable "disable_api_termination" {}
variable "source_dest_check" {}
variable "iam_instance_profile" {}
variable "private_ip" {}

variable "vpc_security_group_ids" {
  type = "list"
}

# Root device
variable "root_volume_type" {}

variable "root_volume_size" {}

# EBS Volume
variable "ebs_device_name" {}

variable "ebs_volume_type" {}
variable "ebs_volume_size" {}

# Instance tagging
variable "Name" {}

variable "Owner" {}
variable "Managed" {}
variable "Environment" {}
variable "Cost" {}
variable "Division" {}
variable "Department" {}
variable "Function" {}
variable "Internal" {}
