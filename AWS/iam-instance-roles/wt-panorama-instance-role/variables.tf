# Tagging variables
variable "Cost" {}
variable "Department" {}
variable "Division" {}
variable "Environment" {}
variable "Monitoring" {}
variable "Owner" {}
variable "Terraform" {}
variable "Use" {}


variable "owner" {
  description = "Owner of the resource"
  default     = "Cloud Team"
}

variable "terraform" {
  description = "How the resource is managed with Terraform"
  default     = "True"
}

variable "division" {
  description = "Operations Division"
  default     = "Operations"
}

variable "department" {
  description = "Department"
  default     = "NCW"
}

variable "use-palo" {
  description = "Use of resource"
  default     = "Palo Alto Firewall"
}

variable "cost-a281" {
  description = "NCW Cost Centre (Sam Horsman)"
  default     = "A281"
}