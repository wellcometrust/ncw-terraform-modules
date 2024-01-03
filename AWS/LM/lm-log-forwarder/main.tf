# LogicMonitor Logs forwarder
resource "aws_cloudformation_stack" "lm_forwarder" {
  name         = "lm-forwarder"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  parameters = {
    FunctionName           = "LMLogsForwarder"
    LMAccessId             = var.lm-access-id
    LMAccessKey            = var.lm-access-key
    LMCompanyName          = "wellcome"
    LMRegexScrub           = ""
    PermissionsBoundaryArn = ""
  }
  template_url = file("${path.module}/files/latest.yaml")
  tags = {
    Name        = "LMLogsForwarder"
    Owner       = var.Owner
    Environment = var.Environment
    Cost        = var.Cost
    Division    = var.Division
    Department  = var.Department
    Monitoring    = var.Monitoring
    Use         = var.Use
    Terraform   = var.Terraform
  }
}