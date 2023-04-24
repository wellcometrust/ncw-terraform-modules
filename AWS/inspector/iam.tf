resource "aws_iam_role" "aws-inspector-role" {
  name_prefix = "AWS-Inspector-${var.inspector_name}"
  assume_role_policy = file("${path.module}/policies/aws_inspector_role.json")
  tags = {
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment    = var.Environment
    Owner = var.Owner
    Terraform = var.Terraform
    Use = var.Use
  }
}

resource "aws_iam_role_policy" "aws-inspector-policy" {
  name_prefix = "cloudwatch-event-inspector-${var.inspector_name}"
  role        = aws_iam_role.aws-inspector-role.id
  policy = file("${path.module}/policies/aws_inspector_role_policy.json")
}
