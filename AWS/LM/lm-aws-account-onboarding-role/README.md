# LM Account Onboarding IAM User

This Module will be deployed in each of the AWS Accounts where we wish to onboard Logic Monitor.

Important Note you will need to get the *STS_External_ID* from the LM Console in order to deploy the IAM Role.  You will not be able to onboard the account without this.  Please see LM documentation on how to find this

## What it does
* Creates an IAM Role called `LM-Account-Onboarding-Role`.  This forms a trust policy using the template file `lm-trust.json.tpl`
* Creates an IAM Policy called `LM-Account-Onboarding-Role-Policy` with an attached policy document called `lm-policy.json`
* Creates an IAM Policy attachment called `svc_logicmonitor-user-group` and Attaches the policy and the Role to it.

## How to Use
Create a module block in your TF and supply it with the source
```
module "lm-aws-account-onboarding-role" {
  source                = "github.com/wellcometrust/ncw-terraform-modules/AWS/LM/lm-aws-account-onboarding-role"
  Cost                  = var.Cost
  Department            = var.Department
  Division              = var.Division
  Owner                 = var.Owner
  STS_External_ID       = var.STS_External_ID
  Terraform             = var.Terraform
  Use                   = var.Use
}
```

**Please don't pass STS_External_ID over the CLI!**