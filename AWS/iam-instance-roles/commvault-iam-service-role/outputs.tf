output "wt-commvault-instance-role-arn" {
  value = aws_iam_role.wt-commvault-role.arn
}

output "wt-commvault-instance-role-name" {
  value = aws_iam_role.wt-commvault-role.name
}

output "wt-commvault-instance-role-description" {
  value = aws_iam_role.wt-commvault-role.description
}
