resource "aws_iam_user" "logicmonitor-iam-user" {
  name = "svc_logicmonitor"

  tags = {
    Name        = "svc_logicmonitor"
    Owner       = var.Owner
    Terraform     = var.Terraform
    Environment = "All"
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Use         = var.Use
  }
}

# IAM Policy for Logic Monitor
resource "aws_iam_policy" "logicmonitor-iam-user-policy" {
  policy      = file("${path.module}/policies/logicmonitor-iam-user-policy.json")
  description = "This policy allows access to the resources for LogicMonitor Log Forwarder"
  name        = "svc_logicmnonitor-iam-user-policy"
  tags = {
    Name        = svc_logicmnonitor-iam-user-policy
    Owner       = var.Owner
    Terraform     = var.Terraform
    Environment = "All"
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Use         = var.Use
  }
}

resource "aws_iam_group" "logicmonitor-iam-user-group" {
  name = "svc_logicmonitor-user-group"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "logicmonitor-iam-user-group-policy-attachment" {
  group      = aws_iam_group.logicmonitor-iam-user-group.name
  policy_arn = aws_iam_policy.logicmonitor-iam-user-policy.id
}

resource "aws_iam_user_group_membership" "logicmonitor-iam-user-group-membership" {
  groups = [aws_iam_group.logicmonitor-iam-user-group.name]
  user   = aws_iam_user.logicmonitor-iam-user.name
}
