data "aws_inspector_rules_packages" "inspector-rules" {}

locals {
  rules_package_arns = length(var.inspector_rule_arns) == 0 ? join(",", data.aws_inspector_rules_packages.inspector-rules.arns) : join(",", var.inspector_rule_arns)
}

resource "aws_inspector_resource_group" "inspector-group" {
  tags = var.inspector_tags
}

resource "aws_inspector_assessment_target" "inspector-assessment-target" {
  name               = var.inspector_name
  resource_group_arn = aws_inspector_resource_group.inspector-group.arn
}

resource "aws_inspector_assessment_template" "inspector-assessment-template" {
  name       = var.inspector_name
  target_arn = aws_inspector_assessment_target.inspector-assessment-target.arn
  duration   = var.inspector_duration

  rules_package_arns = split(",", local.rules_package_arns)

  tags = {
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment    = var.Environment
    Monitoring    = var.Monitoring
    Owner = var.Owner
    Terraform = var.Terraform
    Use = var.Use
  }
}
