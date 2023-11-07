#LMAccessId =
variable "lm-access-id" {
  description = "The LM API tokens access ID"
  type        = string
  sensitive   = true
}

#LMAccessKey =
variable "lm-access-key" {
  description = "The LM API tokens access key"
  type        = string
  sensitive   = true
}

# Tagging Variables
variable "Cost" {}
variable "Department" {}
variable "Division" {}
variable "Environment" {}
variable "Monitoring" {}
variable "Owner" {}
variable "Terraform" {}
variable "Use" {}