variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the CloudFront site."
}

variable "tf_state_bucket_names" {
  type        = map(string)
  description = "Map of member account ID to Terraform state bucket name."
}

variable "tags" {
  type    = map(string)
  default = {}
}
