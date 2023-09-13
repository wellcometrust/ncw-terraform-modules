# LM Log Forwarder IAM User

This Module will be deployed in each of the AWS Accounts where we wish to create a service account for LM to utilise.

## What it does
* Creates an IAM User called `svc_logicmonitor`
* Create an IAM Policy called `svc_logicmnonitor-iam-user-policy` with an attached policy document called `logicmonitor-iam-user-policy.json`
* Creates an IAM User Group `svc_logicmonitor-user-group` and Attaches the policy and the User to it.

## How to Use
Create a module block in your TF and supply it with the source
```
module "svc-logicmonitor-user" {
  source                = "github.com/wellcometrust/ncw-terraform-modules/AWS/LM/lm-svc-account-iam-user"
  -iam-user"
  Cost                  = var.Cost
  Department            = var.Department
  Division              = var.Division
  Environment           = var.Environment
  Owner                 = var.Owner
  Terraform             = var.Terraform
  Use                   = var.Use
}
```

## After Creation
You will need to create a secret key for each user and store those details securely in password manager.
