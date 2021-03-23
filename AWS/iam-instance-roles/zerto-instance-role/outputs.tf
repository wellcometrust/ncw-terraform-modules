output "zerto-instance-role-arn" {
  value = aws_iam_role.zerto-instance-role.arn
}

output "zerto-instance-role-name" {
  value = aws_iam_role.zerto-instance-role.name
}

output "zerto-instance-role-description" {
  value = aws_iam_role.zerto-instance-role.description
}