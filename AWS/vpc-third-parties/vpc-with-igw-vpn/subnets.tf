# Subnets on this VPC (one per zone in the region)
resource "aws_subnet" "prod_a" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(var.cidr_block, 2, 0)
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags {
    Name        = "${var.vpc_name} - Prod Public - Subnet A"
    Owner       = var.Owner
    Managed     = var.Managed
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Division
  }
}

resource "aws_subnet" "prod_b" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(var.cidr_block, 2, 1)
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags {
    Name        = "${var.vpc_name} - Prod Public - Subnet B"
    Owner       = var.Owner
    Managed     = var.Managed
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Division
  }
}

resource "aws_subnet" "prod_c" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(var.cidr_block, 2, 2)
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags {
    Name        = "${var.vpc_name} - Prod Private - Subnet C"
    Owner       = var.Owner
    Managed     = var.Managed
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Division
  }
}

resource "aws_subnet" "prod_d" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(var.cidr_block, 2, 3)
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags {
    Name        = "${var.vpc_name} - Prod Private - Subnet D"
    Owner       = var.Owner
    Managed     = var.Managed
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Division
  }
}

# Start of third party infra structure acl
resource "aws_network_acl" "aws-third-party-infrastructure-acl" {
  vpc_id     = aws_vpc.prod.id
  subnet_ids = [aws_subnet.prod_a.id, aws_subnet.prod_b.id, aws_subnet.prod_c.id, aws_subnet.prod_d.id]

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    icmp_code  = 0
    icmp_type  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    icmp_code  = 0
    icmp_type  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  tags {
    Name        = "${var.vpc_name} - ACL"
    Owner       = var.Owner
    Managed     = var.Managed
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Division
  }
}
