# IAM Role for ThreatAware
resource "aws_iam_role" "wt-ta-role" {
  assume_role_policy   = file("${path.module}/policies/wt-ta-role.json")
  description          = "ThreatAware API Connector to AWS"
  max_session_duration = 7200
  name                 = "ta-app-role"

  tags = {
    Name        = "ta-app-role"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy_attachment" "wt-ta-role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  ])

  role       = aws_iam_role.wt-ta-role.name
  policy_arn = each.value
}

resource "aws_iam_policy" "wt-ta-policy" {
  policy      = file("${path.module}/policies/wt-ta-policy.json")
  description = "This policy allows SSM-Describe-Instance-Info for ThreatAware"
  name        = "wt-ta-policy"

  tags = {
    Name        = "wt-ta-policy"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy_attachment" "wt-ta-policy-attachment" {
  policy_arn = aws_iam_policy.wt-ta-policy.arn
  role       = aws_iam_role.wt-ta-role.name
}