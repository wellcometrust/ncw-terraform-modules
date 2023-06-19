resource "aws_iam_role" "vpc_flow_logs_role" {
  name               = "vpc-flow-logs-role"
  description        = "Allows Flow Logging to Cloudwatch"
  assume_role_policy = file("${path.module}/policies/ec2iam-flow-logs-role.json")

  tags={
    Name        = "VPC Flow Logs Role"
    Owner       = var.Owner
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Internal    = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs_role_policy" {
  name = "vpc-flow-logs-role-policy"
  policy = file("${path.module}/policies/ec2iam-flow-logs-role-actions.json")
  role   = aws_iam_role.vpc_flow_logs_role.id
}
