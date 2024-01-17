output "wt-panorama-instance-role-arn" {
  value = aws_iam_role.wt-panorama-cross-account-instance-role.arn
}

output "wt-panorama-instance-role-name" {
  value = aws_iam_role.wt-panorama-cross-account-instance-role.name
}

output "wt-panorama-instance-role-description" {
  value = aws_iam_role.wt-panorama-cross-account-instance-role.description
}
