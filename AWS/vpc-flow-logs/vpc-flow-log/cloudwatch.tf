# Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "prod-vpc-flow-log-group" {
  name              = "${var.name}_vpc_log_group"
  retention_in_days = 90

  tags {
    Name    = "${var.name} - VPC Log Group"
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Use           = var.Use
  }
}
