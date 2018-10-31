resource "aws_eip" "eip" {
  instance = "${aws_instance.ec2-eip.id}"
  vpc      = true

  tags {
    Name        = "${var.instance_name} - EIP"
    Owned       = "${var.instance_owner}"
    Managed     = "${var.instance_managed}"
    Environment = "${var.instance_environment}"
    Billing     = "${var.cost_centre}"
  }
}
