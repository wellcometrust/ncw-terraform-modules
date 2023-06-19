# VPC Flow Logs for VPC
resource "aws_flow_log" "prod-vpc-flow-log" {
  iam_role_arn   = var.vpc_flow_log_role_arn
  log_destination = aws_cloudwatch_log_group.vpc-flow-log-group.arn
  log_destination_type = "cloud-watch-logs"
  vpc_id         = var.vpc_id
  traffic_type   = "ALL"

  tags={
    Name        = "${var.vpc_name} - VPC Flow Log"
    Owner       = var.Owner
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Internal    = var.Terraform
    Use         = var.Use
  }
}
