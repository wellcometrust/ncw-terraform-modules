# IAM Policy for Commvault
resource "aws_iam_policy" "commvault-iam-user-policy" {
  policy      = file("${path.module}/policies/commvault-iam-user.json")
  description = "This policy allows access to the resources for Commvault"
  name        = "commvault-iam-user-policy"
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
