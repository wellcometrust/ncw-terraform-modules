resource "aws_instance" "ec2-eip" {
  ami                     = "${var.ami}"
  instance_type           = "${var.instance_type}"
  key_name                = "${var.key_pair}"
  subnet_id               = "${var.subnet_id}"
  disable_api_termination = "${var.disable_api_termination}"
  source_dest_check       = "${var.source_dest_check}"
  ebs_optimized           = false
  iam_instance_profile    = "${var.iam_instance_profile}"

  vpc_security_group_ids = [
    "${var.vpc_security_group_ids}",
  ]

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }

  tags {
    Name        = "${var.Name} - Instance"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Department}"
    Internal    = "${var.Internal}"
  }
}
