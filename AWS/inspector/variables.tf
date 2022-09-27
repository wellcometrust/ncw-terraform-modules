variable "inspector_rule_arns" {
  description = "Package arns to use for testing all the packages rules are in for default."
  default = []
}

variable "inspector_duration" {
  description = "Inspector assessment duration in seconds."
  default     = "3600"
}

# Change variable to shedule run to whenever you want e.g. default = "cron(0 15 ? * MON *)"
variable "inspector_schedule_expression" {
  description = "When AWS inspector should run."
  default = "cron(0 19 ? * SUN *)"
}

variable "inspector_name" {
  description = "Name of your assessment"
}

variable "inspector_tags" {
  description = "Instance tags that you want to include in your security scan"
}

# For Tags -  For our purposes!
variable "Ansible" {}
variable "BackUps" {}
variable "Cost" {}
variable "Department" {}
variable "Division" {}
variable "Environment" {}
variable "Internal" {}
variable "Owner" {}
variable "PatchGroup" {}
variable "Terraform" {}
variable "Use" {}

