output "wt-standard-instance-role-arn" {
  value = aws_iam_role.wt-standard-instance-role-rds-s3.arn
}

output "wt-standard-instance-role-name" {
  value = aws_iam_role.wt-standard-instance-role-rds-s3.name
}

output "wt-standard-instance-role-description" {
  value = aws_iam_role.wt-standard-instance-role-rds-s3.description
}