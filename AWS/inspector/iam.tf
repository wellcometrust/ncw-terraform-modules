resource "aws_iam_role" "aws-inspector-role" {
  name_prefix = "AWS-Inspector-${var.inspector_name}"
  assume_role_policy = file("${path.module}/policies/aws_inspector_role.json")
  tags = {
    Name        = "AWS Inspector Role"
    Owner       = var.owner
    Managed     = var.managed
    Environment = var.environment
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

resource "aws_iam_role_policy" "aws-inspector-policy" {
  name_prefix = "cloudwatch-event-inspector-${var.inspector_name}"
  role        = aws_iam_role.aws-inspector-role.id
  policy = file("${path.module}/policies/aws_inspector_role_policy.json")

}
