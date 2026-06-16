variable "profile" {
  description = "REQUIRED. AWS named profile to use (e.g. \"wellcomedevelopers_AdministratorAccess\")."
  type        = string

  validation {
    condition     = length(trimspace(var.profile)) > 0
    error_message = "profile must be a non-empty AWS named profile."
  }
}

variable "aws_account_id" {
  description = "REQUIRED. 12-digit AWS account ID being scanned. The scanner aborts if STS reports a different account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_account_name" {
  description = "REQUIRED. Human-readable account name (e.g. \"wellcomedevelopers-prod\"). Appears in the banner, report and Slack message."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_account_name)) > 0
    error_message = "aws_account_name must be a non-empty string."
  }
}

variable "repo_name" {
  description = "REQUIRED. Name of this repo (e.g. \"wellcomedevelopers-repo\"). Appears in the banner, report filename and Slack message."
  type        = string

  validation {
    condition     = length(trimspace(var.repo_name)) > 0
    error_message = "repo_name must be a non-empty string."
  }
}

variable "regions" {
  description = "REQUIRED. AWS regions to scan (at least one, e.g. [\"eu-west-1\"])."
  type        = list(string)

  validation {
    condition     = length(var.regions) > 0
    error_message = "regions must contain at least one AWS region."
  }

  validation {
    condition     = alltrue([for r in var.regions : can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", r))])
    error_message = "Every region must be a valid AWS region code (e.g. \"eu-west-1\")."
  }
}

variable "terraform_dir" {
  description = "Path to the Terraform stack to compare against. Defaults to the consumer's root module directory (path.root)."
  type        = string
  default     = ""
}

variable "json_output" {
  description = "If true, the script also writes a machine-readable JSON report alongside the Markdown report."
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Optional Slack webhook URL. When set, the script posts a summary after each scan. Can also be provided via the SLACK_WEBHOOK_URL environment variable or slack_webhook_url in the stack's terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
