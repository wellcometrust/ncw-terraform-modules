# Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc-flow-log-group" {
  name              = "${var.vpc_name}_vpc_flow_log_group"
  retention_in_days = 90

  tags={
    Name        = "${var.vpc_name} - VPC Flow Log Group"
    Owner       = var.Owner
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Monitoring    = var.Monitoring
    Internal    = var.Terraform
    Use         = var.Use
  }
}
