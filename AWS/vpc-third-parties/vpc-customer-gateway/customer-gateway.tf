# Start of Customer Gateway
resource "aws_customer_gateway" "aws-third-party-infrastructure-gateway" {
  bgp_asn    = 65000
  ip_address = "52.215.99.155"
  type       = "ipsec.1"

  tags {
    Name    = "${var.gateway-name}"
    Owner   = "${var.owner}"
    Managed = "${var.managed}"
  }
}
