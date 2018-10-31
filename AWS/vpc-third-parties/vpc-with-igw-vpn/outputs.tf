output "prod_vpc_cidr_block" {
  value = "${aws_vpc.prod.cidr_block}"
}

output "prod_vpc_id" {
  value = "${aws_vpc.prod.id}"
}

output "prod_vpc_subnet_a" {
  value = "${aws_subnet.prod_a.id}"
}

output "prod_vpc_subnet_b" {
  value = "${aws_subnet.prod_b.id}"
}

output "prod_vpc_subnet_c" {
  value = "${aws_subnet.prod_c.id}"
}

output "prod_vpc_subnet_d" {
  value = "${aws_subnet.prod_d.id}"
}

output "virtual_private_gateway" {
  value = "${aws_vpn_gateway.aws-third-party-infrastructure-vpn.id}"
}

output "vpn_connection" {
  value = "${aws_vpn_connection.aws-third-party-infrastructure-vpn.id}"
}
