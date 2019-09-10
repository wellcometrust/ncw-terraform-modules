variable "inspector_rule_arns" {
  description = "Package arns to use for testing all the packages rules are in for default."
  type        = "list"
  default = []
}

variable "inspector_duration" {
  description = "Inspector assessment duration in seconds."
  default     = "3600"
}

# Change variable to shedule run to whenever you want e.g. default = "cron(0 15 ? * MON *)"
variable "inspector_schedule_expression" {
  description = "When AWS inspector should run."
}

variable "inspector_name" {
  description = "Name of your assessment"
}

variable "inspector_tags" {
  description = "Instance tags that you want to include in your security scan"
  type        = "map"
}

# For Tags -  For our purposes!
variable "owner" {
  description = "Owner of the resource"
}

variable "managed" {
  description = "How the resource is managed i.e. Managed by terraform"
}

variable "environment" {
  description = "What is the resources environment i.e. Production"
}

variable "cost" {
  description = "Paying Cost Centre"
}

variable "division" {
  description = "Division the resource is owned by"
}

variable "department" {
  description = "Department the resource is owned by"
}
