# LM Log Forwarder IAM User

This Module will be deployed in each of the AWS Accounts where we wish to create A Log Forwarder that will have the ability to forward CloudTrail and other Logs onto the NCW LogicMonitor Cloud Platform

## What it does
* Creates an IAM User called `svc_logicmonitor`
* Create an IAM Policy called `svc_logicmnonitor-iam-user-policy` with an attached policy document called `logicmonitor-iam-user-policy.json`
* Creates an IAM User Group `svc_logicmonitor-user-group` and Attaches the policy and the User to it.

## How to Use
Create a module block in your TF and supply it with the source
```
module "svc-logicmonitor-user" {
  source                = "github.com/wellcometrust/ncw-terraform-modules/AWS/LM/lm-log-forwarder-iam-user"
  -iam-user"
  Cost                  = var.Cost
  Department            = var.Department
  Division              = var.Division
  Owner                 = var.Owner
  Terraform             = var.Terraform
  Use                   = var.Use
}
```