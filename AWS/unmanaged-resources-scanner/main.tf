locals {
  # Absolute path to the bundled scripts (resolved at terraform init time).
  scripts_dir   = "${path.module}/files"
  wrapper       = "${local.scripts_dir}/all-unmanaged-resources.sh"
  check_script  = "${local.scripts_dir}/check-unmanaged-resources.sh"
  scan_script   = "${local.scripts_dir}/scan-unmanaged-resources.sh"

  # Build the argument list passed to the wrapper.
  mode_flag = var.mode == "check-only" ? "--check-only" : (
    var.mode == "scan-only" ? "--scan-only" : ""
  )

  profile_args = var.profile == "" ? [] : ["--profile", var.profile]
  region_args  = flatten([for r in var.regions : ["--region", r]])
  dir_args     = var.terraform_dir == "" ? [] : ["--dir", var.terraform_dir]
  json_args    = var.json_output ? ["--json"] : []
  mode_args    = local.mode_flag == "" ? [] : [local.mode_flag]

  invocation_args = concat(local.mode_args, local.profile_args, local.region_args, local.dir_args, local.json_args)

  # Shell-safe joined args (used by null_resource and outputs).
  invocation_args_str = join(" ", local.invocation_args)

  effective_cwd = var.working_dir == "" ? path.cwd : var.working_dir
}

# Ensure shipped scripts are executable on the consumer machine after
# `terraform init` copies the module to .terraform/modules/<name>/files/.
# (We chmod every plan to be safe; cost is negligible.)
resource "null_resource" "ensure_executable" {
  triggers = {
    wrapper_hash = filesha256(local.wrapper)
    check_hash   = filesha256(local.check_script)
    scan_hash    = filesha256(local.scan_script)
  }

  provisioner "local-exec" {
    command     = "chmod +x '${local.wrapper}' '${local.check_script}' '${local.scan_script}'"
    interpreter = ["bash", "-c"]
  }
}

# Optional: run the scanner during `terraform apply`.
resource "null_resource" "run" {
  count = var.run_on_apply ? 1 : 0

  triggers = var.triggers

  provisioner "local-exec" {
    working_dir = local.effective_cwd
    command     = "'${local.wrapper}' ${local.invocation_args_str}"
    interpreter = ["bash", "-c"]

    environment = {
      SLACK_ENABLED     = var.slack_enabled ? "1" : "0"
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      ACCOUNT_ID        = var.account_id
      SETUP_SCRIPT      = var.setup_script
    }
  }

  depends_on = [null_resource.ensure_executable]
}

