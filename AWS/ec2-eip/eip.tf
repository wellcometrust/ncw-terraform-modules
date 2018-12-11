resource "aws_eip" "eip" {
  instance = "${aws_instance.ec2-eip.id}"
  vpc      = true

  tags {
    Name        = "${var.Name} - EIP"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Department}"
    Internal    = "${var.Internal}"
  }
}
