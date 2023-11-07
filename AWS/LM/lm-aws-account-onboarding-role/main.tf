# Role to grant LM Access
resource "aws_iam_role" "lm-iam-role" {
  name               = "LM-Account-Onboarding-Role"
  description        = "Role for LM to Utilise to Onboard the Account"
  assume_role_policy = templatefile(("${path.module}/policies/lm-trust.json.tpl"), { STS_External_ID = var.STS_External_ID })
  tags = {
    Name        = "LM-Account-Onboarding-Role"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Monitoring    = var.Monitoring
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_policy" "lm-iam-policy" {
  policy      = file("${path.module}/policies/lm-policy.json")
  description = "Policy for LM to Utilise to Onboard the Account"
  name        = "LM-Account-Onboarding-Role-Policy"
  tags = {
    Name        = "LM-Account-Onboarding-Role-Policy"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Monitoring    = var.Monitoring
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy_attachment" "lm-iam-role-policy-attachment" {
  policy_arn = aws_iam_policy.lm-iam-policy.arn
  role       = aws_iam_role.lm-iam-role.name
}