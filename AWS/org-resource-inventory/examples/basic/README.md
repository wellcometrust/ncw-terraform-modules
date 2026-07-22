# Basic example

Run this from the Organisation management account with credentials that can list AWS Organizations accounts.

```bash
cd ../../
./build.sh
cd examples/basic
terraform init
terraform apply
```

The module requires both the default AWS provider and an `aws.us_east_1` alias for CloudFront-scope WAF resources.
Populate `allowed_cidrs` and `tf_state_bucket_names` in `terraform.tfvars` before applying.
