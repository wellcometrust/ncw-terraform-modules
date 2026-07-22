variable "name_prefix" {
  description = "Prefix used for all created resources."
  type        = string
  default     = "org-inventory"
}

variable "member_role_name" {
  description = "Role name assumed in each member account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "included_account_ids" {
  description = "Account IDs to include. Empty means all active org accounts."
  type        = list(string)
  default     = []
}

variable "excluded_account_ids" {
  description = "Account IDs to exclude."
  type        = list(string)
  default     = []
}

variable "regions" {
  description = "AWS regions to scan for regional services."
  type        = list(string)
  default     = ["eu-west-1", "eu-west-2", "us-east-1"]
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for scanner Lambda."
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "allowed_cidrs" {
  description = "CIDR ranges allowed to access CloudFront via WAF."
  type        = list(string)
}

variable "frontend_domain" {
  description = "Optional CloudFront alias domain name."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN in us-east-1 for the CloudFront alias."
  type        = string
  default     = null

  validation {
    condition     = var.acm_certificate_arn == null || can(regex("^arn:aws[a-z-]*:acm:us-east-1:", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be an ACM certificate ARN in us-east-1."
  }
}

variable "tf_state_bucket_names" {
  description = "Map of account_id => Terraform state bucket name for cross-account state reads."
  type        = map(string)
  default     = {}
}

variable "resource_types" {
  description = "Resource type names to scan. Empty means all registered scanner types."
  type        = list(string)
  default     = []
}

variable "extra_ignore_patterns" {
  description = "Extra case-insensitive substrings that mark matching resources as ignored."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the scanner Lambda."
  type        = number
  default     = 30
}

variable "lambda_timeout" {
  description = "Scanner Lambda timeout in seconds."
  type        = number
  default     = 900
}

variable "lambda_memory_mb" {
  description = "Scanner Lambda memory size in MB."
  type        = number
  default     = 2048
}
