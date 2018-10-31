resource "aws_internet_gateway" "prod" {
  vpc_id = "${aws_vpc.prod.id}"

  tags {
    Name    = "${var.vpc_name} - Prod-gateway"
    Owner   = "${var.owner}"
    Managed = "${var.managed}"
  }
}
