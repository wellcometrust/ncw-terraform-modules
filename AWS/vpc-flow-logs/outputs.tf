output "log-group-arn" {
  value = aws_cloudwatch_log_group.vpc-flow-log-group.arn
}

output "log-group-name" {
  value = aws_cloudwatch_log_group.vpc-flow-log-group.name
}