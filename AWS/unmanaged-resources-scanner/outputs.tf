output "scripts_dir" {
  description = "Absolute path to the directory containing the bundled scanner scripts."
  value       = local.scripts_dir
}

output "wrapper_path" {
  description = "Absolute path to the all-unmanaged-resources.sh wrapper script."
  value       = local.wrapper
}

output "check_script_path" {
  description = "Absolute path to the (portable) check-unmanaged-resources.sh script."
  value       = local.check_script
}

output "scan_script_path" {
  description = "Absolute path to the scan-unmanaged-resources.sh script."
  value       = local.scan_script
}

output "run_command" {
  description = "Ready-to-copy shell command to invoke the scanner with the configured flags."
  value       = trimspace("${local.wrapper} ${local.invocation_args_str}")
}

output "context" {
  description = "Identifying context for this scan (echoed back from inputs)."
  value = {
    profile        = var.profile
    aws_account_id = var.aws_account_id
    repo_name      = var.repo_name
    regions        = var.regions
    terraform_dir  = var.terraform_dir
    mode           = var.mode
  }
}

