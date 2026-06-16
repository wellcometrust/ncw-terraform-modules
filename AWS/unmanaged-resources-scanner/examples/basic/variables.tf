variable "profile" {
  description = "AWS named profile (e.g. 'wellcomedevelopers_AdministratorAccess')."
  type        = string
}

variable "aws_account_id" {
  description = "12-digit AWS account ID being scanned."
  type        = string
}

variable "aws_account_name" {
  description = "Human-readable account name (e.g. 'wellcomedevelopers-prod')."
  type        = string
}

variable "repo_name" {
  description = "Name of this repo (e.g. 'wellcomedevelopers-repo')."
  type        = string
}

variable "regions" {
  description = "AWS regions to scan (at least one)."
  type        = list(string)
}

variable "terraform_dir" {
  description = "Path to the Terraform stack to compare against."
  type        = string
  default     = ""
}

variable "json_output" {
  description = "If true, also write a JSON report."
  type        = bool
  default     = false
}
