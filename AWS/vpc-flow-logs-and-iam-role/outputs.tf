output "log-group-arn" {
  value = aws_cloudwatch_log_group.vpc-flow-log-group.arn
}

output "log-group-name" {
  value = aws_cloudwatch_log_group.vpc-flow-log-group.name
}

output "vpc-flow-log-role-arn" {
  value = aws_iam_role.vpc_flow_logs_role.arn
}
