terraform {
  required_version = ">= 1.5"
}

# Consume the scanner module.
# In your real consumer repo, replace `source` with the git URL of your
# terraform-modules repo, for example:
#
#   source = "git::https://github.com/<your-org>/<your-modules>.git//unmanaged-resources-scanner?ref=v1.0.0"
#
module "unmanaged_scan" {
  source = "../../"

  # All five of these are now REQUIRED.
  profile          = var.profile
  aws_account_id   = var.aws_account_id
  aws_account_name = var.aws_account_name
  repo_name        = var.repo_name
  regions          = var.regions

  terraform_dir  = var.terraform_dir
  mode           = var.mode
  run_on_apply   = var.run_on_apply
  json_output    = var.json_output
  strict_profile = var.strict_profile
  dry_run        = var.dry_run

  # Avoid interactive prompts when run via Terraform.
  account_id = var.aws_account_id

  # Force a re-run every apply when running in CI mode.
  triggers = var.run_on_apply ? { always = timestamp() } : {}
}

output "scan_command" {
  description = "Copy-paste this to run the scanner manually."
  value       = module.unmanaged_scan.run_command
}

output "scan_context" {
  description = "Echo of the inputs used for this scan."
  value       = module.unmanaged_scan.context
}

