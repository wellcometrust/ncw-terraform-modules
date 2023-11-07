variable "owner" {
  description = "Owner of the resource, who should be contacted in case of issue"
  default     = "Cloud Team"
}

variable "terraform" {
  description = "How the resource is managed"
  default     = "True"
}

variable "division" {
  description = "D&T Division"
  default     = "Operations"
}

variable "department" {
  description = "Department"
  default     = "NCW"
}

variable "use-commvault" {
  description = "Use of resource"
  default     = "Commvault"
}

variable "cost-a281" {
  description = "Sams Cost Centre"
  default     = "A281"
}

variable "iam-user-name" {}
variable "Monitoring" {}