resource "aws_instance" "ec2-with-ebs" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_pair}"
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = "${var.associate_public_ip}"
  disable_api_termination     = "${var.disable_api_termination}"
  source_dest_check           = "${var.source_dest_check}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  ebs_optimized               = true

  vpc_security_group_ids = [
    "${var.vpc_security_group_ids}",
  ]

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }

  ebs_block_device {
    device_name = "${var.ebs_device_name}"
    volume_type = "${var.ebs_volume_type}"
    volume_size = "${var.ebs_volume_size}"
  }

  tags {
    Name        = "${var.instance_name}"
    Owned       = "${var.instance_owner}"
    Managed     = "${var.instance_managed}"
    Internal    = "${var.instance_internal_name}"
    Environment = "${var.instance_environment}"
    Billing     = "${var.cost_centre}"
  }
}
