variable "profile" {
  description = "AWS named profile to scan against (e.g. 'my-account_AdministratorAccess')."
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID being scanned. Used purely for context/labeling."
  type        = string
}

variable "repo_name" {
  description = "Name of the infra repo this scanner is being run against (e.g. 'ncw-dev-infra')."
  type        = string
}

variable "regions" {
  description = "AWS regions to scan. Leave [] to auto-discover from the Terraform stack."
  type        = list(string)
  default     = []
}

variable "terraform_dir" {
  description = "Path to the Terraform stack directory to compare against."
  type        = string
  default     = "./aws"
}

variable "mode" {
  description = "Which scanner(s) to run when run_on_apply = true. One of: check-only, scan-only, all."
  type        = string
  default     = "check-only"
}

variable "run_on_apply" {
  description = "If true, run the scanner during `terraform apply` (CI mode)."
  type        = bool
  default     = false
}

variable "json_output" {
  description = "If true, also produce a JSON report."
  type        = bool
  default     = false
}

