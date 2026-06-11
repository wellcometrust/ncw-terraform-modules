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
    profile          = var.profile
    aws_account_id   = var.aws_account_id
    aws_account_name = var.aws_account_name
    repo_name        = var.repo_name
    regions          = var.regions
    terraform_dir    = local.effective_tf_dir
    mode             = var.mode
    strict_profile   = var.strict_profile
    dry_run          = var.dry_run
  }
}

output "readme_path" {
  description = "Filesystem path of the README copy written into the consumer stack. Empty when `install_readme = false`."
  value       = var.install_readme ? local.readme_dest_path : ""
}

output "module_copy_dir" {
  description = "Directory where the full module copy was written. Empty when `install_module_copy = false`."
  value       = var.install_module_copy ? local.module_copy_dest : ""
}

output "module_copy_file_count" {
  description = "Number of files written into the module copy directory (excluding the AUTO_GENERATED.md notice)."
  value       = var.install_module_copy ? length(local.module_copy_files) : 0
}
