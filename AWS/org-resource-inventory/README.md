# AWS Organization Resource Inventory

Org-wide AWS inventory with Terraform-management status and a Firefly-style static UI. A scheduled Lambda in the Organisation account assumes into member accounts, enumerates resources, compares them with Terraform state files in S3, writes JSON reports, and serves the latest report through CloudFront.

```
EventBridge ──▶ Scanner Lambda ──▶ Organizations + STS AssumeRole
                       │                    │
                       │                    ├─ regional/global AWS scanners
                       │                    ├─ Terraform state S3 reads
                       │                    └─ CloudFormation resource IDs
                       ▼
              Reports S3 bucket ◀── CloudFront /api/reports/*
Frontend S3 bucket ◀─────────────── CloudFront /* ◀── WAF IP allow-list
```

## Prerequisites

- Terraform >= 1.5
- Python 3.12 and `pip`
- Node.js 20+ and npm
- AWS administrator credentials in the Organisation management account
- `OrganizationAccountAccessRole` (or `member_role_name`) assumable in each member account
- An `aws.us_east_1` provider alias passed to this module for CloudFront-scope WAF resources

## Build and deploy

```bash
cd AWS/org-resource-inventory
./build.sh
cd examples/basic
terraform init
terraform apply
aws lambda invoke --function-name org-inventory-scanner response.json
```

Open the `cloudfront_domain` output after the first report is written.

## Cross-account Terraform state bucket policy

Add a policy like this to each member account state bucket, replacing the bucket name, Organisation account ID, and Lambda role name/output ARN as appropriate:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOrgInventoryScannerReadState",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::ORG_ACCOUNT_ID:role/org-inventory-scanner" },
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::MEMBER_TF_STATE_BUCKET/*"
    },
    {
      "Sid": "AllowOrgInventoryScannerListState",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::ORG_ACCOUNT_ID:role/org-inventory-scanner" },
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::MEMBER_TF_STATE_BUCKET"
    }
  ]
}
```

## Usage

```hcl
provider "aws" { region = "eu-west-1" }
provider "aws" { alias = "us_east_1" region = "us-east-1" }

module "inventory" {
  source = "./AWS/org-resource-inventory"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  allowed_cidrs = ["203.0.113.10/32"]
  tf_state_bucket_names = {
    "111111111111" = "team-a-terraform-state"
  }
}
```

## Variables

| Name | Type | Default | Description |
|---|---|---:|---|
| `name_prefix` | `string` | `org-inventory` | Prefix for resources. |
| `member_role_name` | `string` | `OrganizationAccountAccessRole` | Role assumed in member accounts. |
| `included_account_ids` | `list(string)` | `[]` | If set, scan only these accounts. |
| `excluded_account_ids` | `list(string)` | `[]` | Accounts to skip. |
| `regions` | `list(string)` | `eu-west-1, eu-west-2, us-east-1` | Regional scan targets. |
| `schedule_expression` | `string` | `cron(0 3 * * ? *)` | Scanner schedule. |
| `allowed_cidrs` | `list(string)` | required | CloudFront WAF allow-list. |
| `frontend_domain` | `string` | `null` | Optional CloudFront alias. |
| `acm_certificate_arn` | `string` | `null` | Optional us-east-1 ACM cert ARN. |
| `tf_state_bucket_names` | `map(string)` | `{}` | Account ID to TF state bucket. |
| `resource_types` | `list(string)` | `[]` | Scanner type subset; empty scans all. |
| `extra_ignore_patterns` | `list(string)` | `[]` | Additional ignored substrings. |
| `tags` | `map(string)` | `{}` | Resource tags. |
| `log_retention_days` | `number` | `30` | Lambda log retention. |
| `lambda_timeout` | `number` | `900` | Lambda timeout. |
| `lambda_memory_mb` | `number` | `2048` | Lambda memory. |

## Outputs

| Name | Description |
|---|---|
| `cloudfront_domain` | CloudFront domain name. |
| `cloudfront_distribution_id` | Distribution ID. |
| `reports_bucket` | JSON report bucket. |
| `frontend_bucket` | Static frontend bucket. |
| `scanner_lambda_arn` | Scanner Lambda ARN. |
| `scanner_lambda_name` | Scanner Lambda name. |
| `waf_ipset_arn` | WAF IP set ARN. |

## Scanner behaviour

The Python scanner preserves the bash scanner's ignore logic: case-insensitive substring matching across type, id, ARN, name, tags, and raw details. Built-ins include `tfstate`, `terraform-state`, `terraform-states`, `Key Pair`, `org-level`, `stacksets`, `QuickSetup`, `quicksetup`, `Softcat`, and `softcat`. Ignored resources remain in `latest.json` with `management_status = "ignored"`.

Global services (IAM, S3, Route53, CloudTrail) scan once per account. Regional services scan every configured region. CloudFormation physical resource IDs are reported as `cloudformation` rather than `unmanaged`.

## IP allow-list and WAF

The WebACL defaults to block and allows only `allowed_cidrs`. To update access, change `allowed_cidrs` and run `terraform apply`. CloudFront WAF resources use the `aws.us_east_1` provider alias because CloudFront-scope WAF is global/us-east-1.

## Roadmap / non-goals

Non-goals for this version: authentication beyond IP allow-list, cost analysis, tag drift, remediation, and historical trend charts. Future work could add signed-in access, trends, cost overlays, and richer state-source discovery.
