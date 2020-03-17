# IAM Policy for Commvault
resource "aws_iam_policy" "commvault-iam-user-policy" {
  policy      = file("${path.module}/policies/commvault-iam-user.json")
  description = "This policy allows access to the resources for Commvault"
  name        = "commvault-iam-user-policy"
}
