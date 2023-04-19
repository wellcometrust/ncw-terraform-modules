# IAM Role for Qualys Connector - CHG0034045
resource "aws_iam_role" "wt-qualys-role" {
  assume_role_policy   = file("${path.module}/policies/wt-qualys-role.json")
  description          = "This role provides read only access for Qualys"
  max_session_duration = 7200
  name                 = "wt-qualys-role"

  tags = {
    Name        = "wt-qualys-role"
    Ansible     = var.Ansible
    BackUps     = var.BackUps
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Internal    = var.Internal
    Owner       = var.Owner
    PatchGroup  = var.PatchGroup
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

# IAM Policy for Qualys Connector - CHG0034045
resource "aws_iam_policy" "wt-qualys-policy" {
  policy      = file("${path.module}/policies/wt-qualys-policy.json")
  description = "This policy allows access to EC2 for Qualys - read only"
  name        = "wt-qualys-policy"

  tags = {
    Name        = "wt-qualys-policy"
    Ansible     = var.Ansible
    BackUps     = var.BackUps
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Internal    = var.Internal
    Owner       = var.Owner
    PatchGroup  = var.PatchGroup
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_role_policy_attachment" "wt-qualys-policy-attachment" {
  policy_arn = aws_iam_policy.wt-qualys-policy.arn
  role       = aws_iam_role.wt-qualys-role.name
}