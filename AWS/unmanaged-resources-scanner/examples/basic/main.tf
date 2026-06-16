terraform {
  required_version = ">= 1.5"
}

# Consume the scanner module. Replace `source` with the git URL:
#   source = "git::https://github.com/wellcometrust/ncw-terraform-modules.git//AWS/unmanaged-resources-scanner?ref=master"
#
module "unmanaged_scan" {
  source = "../../"

  # Required
  profile          = var.profile
  aws_account_id   = var.aws_account_id
  aws_account_name = var.aws_account_name
  repo_name        = var.repo_name
  regions          = var.regions

  # Optional
  terraform_dir = var.terraform_dir
  json_output   = var.json_output
}

output "scan_command" {
  description = "Run this to scan the account."
  value       = module.unmanaged_scan.run_command
}

output "scan_context" {
  description = "Resolved scan context."
  value       = module.unmanaged_scan.context
}
