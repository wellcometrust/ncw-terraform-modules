variable "run_on_apply" {
  description = "If true, runs the scanner during `terraform apply` via a null_resource. Useful for CI. If false, the module just delivers the scripts and outputs the path."
  type        = bool
  default     = false
}

variable "mode" {
  description = "Which scanner(s) to run when run_on_apply = true. One of: check-only, scan-only, all."
  type        = string
  default     = "check-only"
  validation {
    condition     = contains(["check-only", "scan-only", "all"], var.mode)
    error_message = "mode must be one of: check-only, scan-only, all."
  }
}

variable "profile" {
  description = "AWS named profile to pass to the scanner (--profile). Leave empty to rely on the ambient AWS credentials in the environment."
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "(Optional) The AWS account ID this scan targets. Used purely for context/labeling in module outputs — the scanner itself auto-detects the account from STS at runtime."
  type        = string
  default     = ""
}

variable "repo_name" {
  description = "(Optional) The name of the infra repo being scanned. Used purely for context/labeling in module outputs."
  type        = string
  default     = ""
}

variable "regions" {
  description = "AWS regions to scan (--region). Leave empty to let the scanner auto-discover from your Terraform stack."
  type        = list(string)
  default     = []
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

