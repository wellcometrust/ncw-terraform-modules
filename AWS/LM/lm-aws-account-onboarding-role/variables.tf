# Tagging variables
variable "Cost" {}
variable "Department" {}
variable "Division" {}
variable "Environment" {}
variable "Monitoring" {}
variable "Owner" {}
variable "Terraform" {}
variable "Use" {}
variable "STS_External_ID" {
  description = "STS External ID from the LM Console"
  type        = string
  sensitive   = true
}