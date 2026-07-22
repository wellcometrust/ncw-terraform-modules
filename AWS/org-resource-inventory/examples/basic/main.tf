terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "org_resource_inventory" {
  source = "../../"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  allowed_cidrs         = var.allowed_cidrs
  tf_state_bucket_names = var.tf_state_bucket_names

  regions = ["eu-west-1", "eu-west-2", "us-east-1"]
  tags    = var.tags
}
