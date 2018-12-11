# The Prod Route Table for the VPC
# Routing Table
resource "aws_route_table" "prod" {
  vpc_id = "${aws_vpc.prod.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.prod.id}"
  }

  route {
    cidr_block = "10.215.0.0/16"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  route {
    cidr_block = "10.183.0.0/16"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  route {
    cidr_block = "10.70.2.0/24"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  tags {
    Name        = "${var.vpc_name} - Public Route table"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Division}"
  }
}

# Route associations only the public subnets
resource "aws_route_table_association" "prod_a" {
  subnet_id      = "${aws_subnet.prod_a.id}"
  route_table_id = "${aws_route_table.prod.id}"
}

resource "aws_route_table_association" "prod_b" {
  subnet_id      = "${aws_subnet.prod_b.id}"
  route_table_id = "${aws_route_table.prod.id}"
}

# The Private Routing Table for the VPC
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.prod.id}"

  route {
    cidr_block = "10.215.0.0/16"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  route {
    cidr_block = "10.183.0.0/16"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  route {
    cidr_block = "10.70.2.0/24"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
  }

  tags {
    Name        = "${var.vpc_name} - Private Route table"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Division}"
  }
}

# Route associations all route tables
resource "aws_route_table_association" "private_c" {
  subnet_id      = "${aws_subnet.prod_c.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private_d" {
  subnet_id      = "${aws_subnet.prod_d.id}"
  route_table_id = "${aws_route_table.private.id}"
}
