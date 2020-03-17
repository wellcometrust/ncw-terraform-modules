resource "aws_iam_group" "commvault-iam-user-group" {
  name = "CommvaultIAMUser"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "commvault-iam-user-group-policy-attachment" {
  group      = aws_iam_group.commvault-iam-user-group.name
  policy_arn = aws_iam_policy.commvault-iam-user-policy.id
}

resource "aws_iam_user_group_membership" "commvault-iam-user-group-membership" {
  groups = [aws_iam_group.commvault-iam-user-group.name]
  user   = aws_iam_user.comvault-iam-user.name
}
