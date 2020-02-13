output "wt-standard-instance-role-arn" {
  value = aws_iam_role.wt-commvault-role.arn
}

output "wt-standard-instance-role-name" {
  value = aws_iam_role.wt-commvault-role.name
}
