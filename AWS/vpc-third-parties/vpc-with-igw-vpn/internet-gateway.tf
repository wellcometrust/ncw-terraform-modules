resource "aws_internet_gateway" "prod" {
  vpc_id = "${aws_vpc.prod.id}"

  tags {
    Name        = "${var.vpc_name} - Prod-gateway"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Division}"
  }
}
