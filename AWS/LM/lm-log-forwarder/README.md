# LM Log Forwarder

This Module will be deployed in each of the AWS Accounts where we wish to create A Log Forwarder that will have the ability to forward CloudTrail and other Logs onto the NCW LM Cloud Platform

## What it does
* Creates a Cloud Formation Stack called `LMLogsForwarder` with some parameters.  

NB Each time you run a plan on a repo that has the Log forwarder in, it will want to update to ensure we have the  latest version deployed.  This is fine! The Cloud formation Stack is provided by LM and the curled URL ensures we always have the latest version deployed.  Periodically we should delete the .terraform file in our local environment and force it to check if there is a new version of the template.


## How to Use
### Before You Begin
Make sure you deploy the lm-log-forwarder-iam-user module first.  Once the IAM User is deployed you will need to create the Secret Key and pass the details of that as part of this module.


### Once You Have The Above
Create a module block in your TF and supply it with the source
```
module "lm-log-forwarder" {
  source                = "github.com/wellcometrust/ncw-terraform-modules/AWS/LM/lm-log-forwarder"
  Cost                  = var.Cost
  Department            = var.Department
  Division              = var.Division
  Owner                 = var.Owner
  Terraform             = var.Terraform
  Use                   = var.Use
  lm-access-key = var.lm-access-key
  lm-access-id  = var.lm-access-id
}
```

**Please dont pass access keys over the CLI!**