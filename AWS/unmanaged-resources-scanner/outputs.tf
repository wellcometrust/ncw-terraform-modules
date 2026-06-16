output "run_command" {
  description = "The exact shell command to run the scanner. Copy-paste this into your terminal (or use $(terraform output -raw run_command))."
  value       = local.run_command
}

output "scripts_dir" {
  description = "Absolute path to the directory containing the scanner script. Useful if you want to invoke the script directly."
  value       = local.scripts_dir
}

output "context" {
  description = "The resolved scan context - useful for confirming the right account/repo/regions are configured before running."
  value = {
    profile          = var.profile
    aws_account_id   = var.aws_account_id
    aws_account_name = var.aws_account_name
    repo_name        = var.repo_name
    regions          = var.regions
    terraform_dir    = local.effective_tf_dir
  }
}
