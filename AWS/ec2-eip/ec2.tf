resource "aws_instance" "ec2-eip" {
  ami                     = "${var.ami}"
  instance_type           = "${var.instance_type}"
  key_name                = "${var.key_pair}"
  subnet_id               = "${var.subnet_id}"
  disable_api_termination = "${var.disable_api_termination}"
  source_dest_check       = "${var.source_dest_check}"
  ebs_optimized           = false

  vpc_security_group_ids = [
    "${var.vpc_security_group_ids}",
  ]

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }

  tags {
    Name        = "${var.instance_name} - Instance"
    Owned       = "${var.instance_owner}"
    Managed     = "${var.instance_managed}"
    Internal    = "${var.instance_internal_name}"
    Environment = "${var.instance_environment}"
    Billing     = "${var.cost_centre}"
  }
}
