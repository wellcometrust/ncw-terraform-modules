variable "owner" {
  description = "Owner of the resource, who should be contacted in case of issue"
  default     = "Kate Welling"
}

variable "terraform" {
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

variable "ansible" {
  description = "Is the resource managed with ansible"
  default     = "false"
}

variable "internal" {
  description = "Does the resource have an internal domain name"
  default     = "N/a"
}

variable "backups" {
  description = "Does the resource need backups"
  default     = "Not-Required"
}

variable "patchgroup" {
  description = "Does the resource need a patchgroup"
  default     = "Not-Required"
}