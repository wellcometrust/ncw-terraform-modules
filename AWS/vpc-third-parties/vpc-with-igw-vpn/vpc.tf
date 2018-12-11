# The Prod VPC
resource "aws_vpc" "prod" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_classiclink   = "${var.enable_classiclink}"
  enable_dns_support   = "${var.enable_dns_support}"
  instance_tenancy     = "default"

  tags {
    Name        = "${var.vpc_name} - VPC"
    Owner       = "${var.Owner}"
    Managed     = "${var.Managed}"
    Environment = "${var.Environment}"
    Cost        = "${var.Cost}"
    Division    = "${var.Division}"
    Department  = "${var.Division}"
  }
}
