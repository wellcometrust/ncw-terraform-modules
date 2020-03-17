resource "aws_iam_user" "comvault-iam-user" {
  name = var.iam-user-name

  tags = {
    Name        = var.iam-user-name
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost-a281
    Division    = var.division
    Department  = var.department
    Inspector   = var.inspector
    Use         = var.use-commvault
  }
}

