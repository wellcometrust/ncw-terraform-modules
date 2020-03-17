resource "aws_iam_user" "comvault-iam-user" {
  name = "CommvaultUser"

  tags = {
    Name        = "Commvault_IAM_User"
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

