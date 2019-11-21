resource "aws_iam_role" "vpc_flow_logs_role" {
  name               = "${var.name}-vpc-flow-logs-role"
  description        = "Allows Flow Logging to Cloudwatch"
  assume_role_policy = file("${path.module}/policies/ec2iam-flow-logs-role.json")
}
