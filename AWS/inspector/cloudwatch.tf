resource "aws_cloudwatch_event_rule" "aws-inspector" {
  name                = "aws-inspector-run-${var.inspector_name}"
  description         = "AWS Inspector run for ${var.inspector_name}"
  schedule_expression = var.inspector_schedule_expression
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

resource "aws_cloudwatch_event_target" "aws-inspector" {
  rule     = aws_cloudwatch_event_rule.aws-inspector.name
  arn      = aws_inspector_assessment_template.inspector-assessment-template.arn
  role_arn = aws_iam_role.aws-inspector-role.arn
}
