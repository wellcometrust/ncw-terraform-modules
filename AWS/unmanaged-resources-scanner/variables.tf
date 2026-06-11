variable "run_on_apply" {
  description = "If true, runs the scanner during `terraform apply` via a null_resource. Useful for CI. If false, the module just delivers the scripts and outputs the path."
  type        = bool
  default     = false
}

variable "dry_run" {
  description = "If true, the scanner only verifies auth + prints the resolved context (account, profile, TF dir, regions, repo) and exits BEFORE enumerating any AWS resources. Use this for the first apply in a new repo to confirm you're pointed at the right account."
  type        = bool
  default     = false
}

variable "mode" {
  description = "Which scanner(s) to run when run_on_apply = true. One of: check-only, scan-only, all. Use 'check-only' for the portable scanner that works in any account."
  type        = string
  default     = "check-only"
  validation {
    condition     = contains(["check-only", "scan-only", "all"], var.mode)
    error_message = "mode must be one of: check-only, scan-only, all."
  }
}

variable "profile" {
  description = "REQUIRED. AWS named profile to pass to the scanner (--profile). The scanner will refuse to silently fall back to ambient credentials."
  type        = string

  validation {
    condition     = length(trimspace(var.profile)) > 0
    error_message = "profile must be a non-empty AWS named profile (e.g. \"wellcomedevelopers_AdministratorAccess\")."
  }
}

variable "aws_account_id" {
  description = "REQUIRED. The 12-digit AWS account ID this scan is permitted to target. The scanner aborts before touching AWS if `aws sts get-caller-identity` reports a different account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_account_name" {
  description = "REQUIRED. Human-readable name of the AWS account being scanned (e.g. \"wellcomedevelopers-prod\"). Used in the banner, report header, report filename and Slack notification so the operator can immediately see which account is being scanned."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_account_name)) > 0
    error_message = "aws_account_name must be a non-empty human-readable account name."
  }
}

variable "repo_name" {
  description = "REQUIRED. The name of the infra repo being scanned (e.g. \"wellcomedevelopers-repo\"). Used in the banner, report header, report filename and Slack notification."
  type        = string

  validation {
    condition     = length(trimspace(var.repo_name)) > 0
    error_message = "repo_name must be a non-empty repository name."
  }
}

variable "regions" {
  description = "REQUIRED. AWS regions to scan (--region). Pass an explicit list - auto-discovery is disabled to prevent silently scanning regions you didn't intend."
  type        = list(string)

  validation {
    condition     = length(var.regions) > 0
    error_message = "regions must contain at least one AWS region (e.g. [\"eu-west-1\"])."
  }

  validation {
    condition     = alltrue([for r in var.regions : can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", r))])
    error_message = "every region must be a valid AWS region code (e.g. \"eu-west-1\", \"us-east-1\")."
  }
}

variable "terraform_dir" {
  description = "Path to the Terraform stack to scan (--dir). Leave empty to let the scanner auto-detect (./aws, ./terraform, or .)."
  type        = string
  default     = ""
}

variable "json_output" {
  description = "If true, pass --json to the check script (writes machine-readable JSON in addition to Markdown)."
  type        = bool
  default     = false
}

variable "working_dir" {
  description = "Directory where the scanner should write its output reports. Defaults to the consumer's current working directory."
  type        = string
  default     = ""
}

variable "triggers" {
  description = "Optional map of triggers that force the null_resource to re-run on change (only used when run_on_apply = true). Common pattern: { always = timestamp() }."
  type        = map(string)
  default     = {}
}

variable "slack_enabled" {
  description = "If true (default), the check script will try to send a Slack notification using `slack_webhook_url` from the Terraform stack's terraform.tfvars (or $SLACK_WEBHOOK_URL). Set to false to suppress Slack entirely."
  type        = bool
  default     = true
}

variable "slack_webhook_url" {
  description = "Optional Slack webhook URL to send the report to. Overrides any `slack_webhook_url` found in the stack's terraform.tfvars. Leave empty to use the tfvars value or disable Slack."
  type        = string
  default     = ""
  sensitive   = true
}

variable "account_id" {
  description = "AWS account ID passed to the wrapper script. When run via Terraform this avoids interactive prompts. When running the script manually, omit this and you will be prompted."
  type        = string
  default     = ""
}

variable "setup_script" {
  description = "Path to a setup/login script shown in error messages when authentication fails. When run via Terraform this avoids interactive prompts. When running the script manually, omit this and you will be prompted."
  type        = string
  default     = ""
}

variable "strict_profile" {
  description = "If true, the scanner will refuse to run unless an explicit AWS profile is provided (via the `profile` variable, the AWS_PROFILE environment variable, or a `--profile` flag). This prevents accidental scans against whatever ambient credentials happen to be loaded."
  type        = bool
  default     = false
}

variable "install_readme" {
  description = "If true (default), write a copy of the module's README into the consumer's stack so users can read the docs without having to navigate back to the modules repo. Disable to opt out."
  type        = bool
  default     = true
}

variable "readme_destination" {
  description = "Where to write the README copy when `install_readme = true`. Defaults to `<path.root>/UNMANAGED_RESOURCES_SCANNER.md`. Set to an absolute path or one relative to the consumer's root module."
  type        = string
  default     = ""
}

variable "install_module_copy" {
  description = "If true, mirror the entire module (Terraform source, scripts, README, examples) into the consumer's stack so it can be reviewed without leaving the repo. Each file is managed by Terraform as a `local_file` resource."
  type        = bool
  default     = false
}

variable "module_copy_destination" {
  description = "Directory (absolute or relative to `path.root`) where the module copy is written when `install_module_copy = true`. Defaults to `<path.root>/.unmanaged-resources-scanner-module/`."
  type        = string
  default     = ""
}

variable "module_copy_exclude" {
  description = "Glob patterns (relative to the module root) to exclude from the module copy. Defaults exclude the examples directory and Terraform lock files."
  type        = list(string)
  default = [
    "examples/**",
    ".terraform/**",
    ".terraform.lock.hcl",
    "**/.DS_Store",
  ]
}
