variable "owner" {
  description = "Owner of the resource, who should be contacted in case of issue"
  default     = "Kate Welling"
}

variable "managed" {
  description = "How the resource is managed"
  default     = "Managed by Terraform"
}

variable "division" {
  description = "D&T Division"
  default     = "Finance / Grants / Digital and Technology / Facilities / Workplace"
}

variable "inspector" {
  description = "Used for AWS Inspector set to True for resource to be included"
  default     = "True"
}

variable "department" {
  description = "Department"
  default     = "Digital and Technology"
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
