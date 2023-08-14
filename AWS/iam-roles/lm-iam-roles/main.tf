# Role to grant LM Access
resource "aws_iam_role" "lm-iam-role" {
  name               = "LM-Role"
  description        = "Role for LM to Utilise"
  assume_role_policy = templatefile(("${path.module}/policies/lm-trust.json.tpl"), { STS_External_ID = var.STS_External_ID })
  tags = {
    Name        = "LM Role"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_policy" "lm-iam-policy" {
  policy      = file("${path.module}/policies/lm-policy.json")
  description = "Policy for LM to Utilise"
  tags = {
    Name        = "LM Policy"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy_attachment" "lm-iam-role-policy-attachment" {
  policy_arn = aws_iam_policy.lm-iam-policy.arn
  role       = aws_iam_role.lm-iam-role.name
}