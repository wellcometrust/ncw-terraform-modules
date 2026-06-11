variable "profile" {
  description = "AWS named profile to scan against (e.g. 'wellcomedevelopers_AdministratorAccess')."
  type        = string
}

variable "aws_account_id" {
  description = "The 12-digit AWS account ID being scanned. Enforced by the scanner against STS."
  type        = string
}

variable "aws_account_name" {
  description = "Human-readable name of the AWS account (e.g. 'wellcomedevelopers-prod')."
  type        = string
}

variable "repo_name" {
  description = "Name of the infra repo this scanner is being run against (e.g. 'wellcomedevelopers-repo')."
  type        = string
}

variable "regions" {
  description = "AWS regions to scan. At least one required."
  type        = list(string)
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

variable "strict_profile" {
  description = "If true, the scanner refuses to run unless an explicit AWS profile is supplied (recommended when consuming this module from any repo)."
  type        = bool
  default     = true
}

variable "dry_run" {
  description = "If true, skip the actual scan and only print the resolved context (account, profile, TF dir, regions, repo) so you can verify it before doing a real run."
  type        = bool
  default     = false
}
