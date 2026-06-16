locals {
  # Absolute path to the scan script (resolved at terraform init time so the
  # consumer can run it directly from .terraform/modules/).
  scripts_dir = "${path.module}/files"
  scan_script = "${local.scripts_dir}/check-unmanaged-resources.sh"

  # Consumer's root module directory is the default Terraform state source
  # and report output location.
  effective_tf_dir = var.terraform_dir != "" ? var.terraform_dir : path.root

  # Build the exact CLI invocation so the consumer can copy-paste it.
  run_args = concat(
    ["--profile", var.profile],
    flatten([for r in var.regions : ["--region", r]]),
    ["--dir", local.effective_tf_dir],
    ["--expected-account", var.aws_account_id],
    ["--account-name", var.aws_account_name],
    ["--repo", var.repo_name],
    var.json_output ? ["--json"] : [],
  )

  run_command = "${local.scan_script} ${join(" ", local.run_args)}"
}

# Make the script executable after `terraform init` copies the module into
# .terraform/modules/. Re-runs only when the script content changes.
resource "null_resource" "ensure_executable" {
  triggers = {
    script_hash = filesha256(local.scan_script)
  }

  provisioner "local-exec" {
    command     = "chmod +x '${local.scan_script}'"
    interpreter = ["bash", "-c"]
  }
}
