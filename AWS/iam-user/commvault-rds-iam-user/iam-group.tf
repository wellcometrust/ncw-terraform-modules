resource "aws_iam_group" "commvault-rds-iam-user-group" {
  name = "CommvaultRDSIAMUser"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "commvault-rds-iam-user-group-policy-attachment" {
  group      = aws_iam_group.commvault-rds-iam-user-group.name
  policy_arn = aws_iam_policy.commvault-rds-iam-user-policy.id
}

resource "aws_iam_user_group_membership" "commvault-rds-iam-user-group-membership" {
  groups = [aws_iam_group.commvault-rds-iam-user-group.name]
  user   = aws_iam_user.commvault-rds-iam-user.name
}
