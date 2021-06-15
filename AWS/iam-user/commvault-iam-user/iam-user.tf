resource "aws_iam_user" "comvault-iam-user" {
  name = var.iam-user-name

  tags = {
    Name        = var.iam-user-name
    Owner       = var.owner
    Terraform     = var.terraform
    Environment = "All"
    Internal    = var.internal
    Cost        = var.cost-a281
    Division    = var.division
    Department  = var.department
    Inspector   = var.inspector
    Use         = var.use-commvault
    BackUps     = var.backups
    Ansible     = var.ansible
    PatchGroup  = var.patchgroup
  }
}

