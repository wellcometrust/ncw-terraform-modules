resource "aws_iam_user" "comvault-iam-user" {
  name = var.iam-user-name

  tags = {
    Name        = var.iam-user-name
    Owner       = var.owner
    Terraform     = var.terraform
    Environment = "All"
    Cost        = var.cost-a281
    Division    = var.division
    Department  = var.department
    Use         = var.use-commvault
  }
}

