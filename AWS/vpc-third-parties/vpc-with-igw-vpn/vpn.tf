# New VPN to Infrastructure Team Account
# Start of virtual private gateway
resource "aws_vpn_gateway" "aws-third-party-infrastructure-vpn" {
  vpc_id = aws_vpc.prod.id

  tags {
    Name        = var.vpn-gateway-name
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Use           = var.Use
    Monitoring    = var.Monitoring
  }
}

resource "aws_vpn_connection" "aws-third-party-infrastructure-vpn" {
  customer_gateway_id = var.gateway-id
  static_routes_only  = true
  type                = "ipsec.1"
  vpn_gateway_id      = aws_vpn_gateway.aws-third-party-infrastructure-vpn.id

  tags {
    Name        = var.vpn-connection-name
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Use           = var.Use
    Monitoring    = var.Monitoring
  }
}

resource "aws_vpn_connection_route" "aws-third-party-infrastructuree-vpn" {
  destination_cidr_block = "10.215.0.0/16"
  vpn_connection_id      = aws_vpn_connection.aws-third-party-infrastructure-vpn.id
}

resource "aws_vpn_connection_route" "aws-third-party-infrastructure-1" {
  destination_cidr_block = "10.215.0.0/16"
  vpn_connection_id      = aws_vpn_connection.aws-third-party-infrastructure-vpn.id
}

resource "aws_vpn_connection_route" "aws-third-party-infrastructure-2" {
  destination_cidr_block = "0.0.0.0/0"
  vpn_connection_id      = aws_vpn_connection.aws-third-party-infrastructure-vpn.id
}

resource "aws_vpn_connection_route" "aws-third-party-infrastructure-3" {
  destination_cidr_block = "10.70.2.0/24"
  vpn_connection_id      = aws_vpn_connection.aws-third-party-infrastructure-vpn.id
}
