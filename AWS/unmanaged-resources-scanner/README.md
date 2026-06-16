# unmanaged-resources-scanner

Compares the live AWS account against a Terraform remote state and reports
every resource that exists in AWS but is **not** tracked in state.

The module does two things:

1. **Delivers** the scan script into `.terraform/modules/` on `terraform init`.
2. **Outputs** the exact command to run the scan — pre-filled with your account,
   profile, regions and repo name.

You run `terraform init` once (or `terraform init -upgrade` to pull the latest
version), then call `$(terraform output -raw scan_command)` whenever you want a
scan. Terraform is not involved in running the scan itself.

---

## Quick start

### 1. Add to your repo

Create `unmanaged-resources-scanner.tf` (or add to an existing `.tf` file):

```hcl
module "unmanaged_resources_scanner" {
  source = "git::https://github.com/wellcometrust/ncw-terraform-modules.git//AWS/unmanaged-resources-scanner?ref=master"

  profile          = "wellcomedevelopers_AdministratorAccess"
  aws_account_id   = "111122223333"
  aws_account_name = "wellcomedevelopers-prod"
  repo_name        = "wellcomedevelopers-repo"
  regions          = ["eu-west-1", "eu-west-2"]
}

output "scan_command" {
  value = module.unmanaged_resources_scanner.run_command
}
```

### 2. Initialise

```bash
terraform init -upgrade
terraform apply   # just chmod's the script - takes < 1 second, touches nothing in AWS
```

### 3. Run the scan

```bash
# Log in first
aws sso login --profile wellcomedevelopers_AdministratorAccess

# Run the scan (copy the command from the output, or use $(...) directly)
$(terraform output -raw scan_command)
```

The scanner prints a banner confirming the account/profile/repo, then scans
25+ resource types and writes two files:

- `unmanaged-resources-<repo>-<account-name>-<account-id>-<timestamp>.md`
- `unmanaged-resources-<repo>-<account-name>-<account-id>-<timestamp>.json`

---

## How the account guard works

The script immediately calls `aws sts get-caller-identity` and compares the
result against `aws_account_id`. If they don't match it aborts with a clear
error before touching anything:

```
[ERR]  Account mismatch: STS reports '999900001111' but expected '111122223333'.
[ERR]  Check that you are logged in with the right profile:
[ERR]    aws sso login --profile wellcomedevelopers_AdministratorAccess
```

This is the core portability guarantee — it is impossible to silently scan the
wrong account.

---

## Variables

### Required

| Name | Description |
|---|---|
| `profile` | AWS named profile (e.g. `"wellcomedevelopers_AdministratorAccess"`). |
| `aws_account_id` | 12-digit AWS account ID. Enforced against STS before any scan. |
| `aws_account_name` | Human-readable account name. Appears in the banner, report filename and Slack. |
| `repo_name` | Name of this repo. Appears in the banner, report filename and Slack. |
| `regions` | List of regions to scan — at least one required. |

### Optional

| Name | Default | Description |
|---|---|---|
| `terraform_dir` | `path.root` | Terraform stack to compare against. |
| `json_output` | `false` | Also write a machine-readable JSON report. |
| `slack_webhook_url` | `""` | Post a summary to Slack after the scan. |

---

## Outputs

| Name | Description |
|---|---|
| `run_command` | The exact shell command to run the scan. |
| `scripts_dir` | Absolute path to the directory containing the script. |
| `context` | Map of all resolved inputs — useful for confirming config before scanning. |

---

## How it works

1. **Reads Terraform state** — runs `terraform show -json` against the stack
   in `terraform_dir` to extract every managed resource identifier (IDs, ARNs,
   names, tags).
2. **Reads CloudFormation** — collects all active CFN stack `PhysicalResourceId`
   values so StackSets-managed resources are not flagged.
3. **Scans live AWS** — queries 25+ resource types across all specified regions
   (EC2, VPC, IAM, S3, Lambda, RDS, ECS, KMS, CloudTrail, etc.).
4. **Compares** — anything in AWS that is not in Terraform state or
   CloudFormation is flagged as unmanaged.
5. **Reports** — writes Markdown and JSON reports, optionally posts to Slack.

### Built-in ignore patterns

Common false positives are suppressed automatically:

| Pattern | Suppresses |
|---|---|
| `tfstate`, `terraform-state`, `terraform-states` | State backend buckets |
| `Key Pair` | EC2 key pairs (usually imported manually) |
| `org-level`, `stacksets`, `QuickSetup`, `quicksetup` | AWS org-managed resources |

The S3 backend bucket declared in your stack's `terraform.tf` is also
auto-discovered and added to the ignore list.

---

## Requirements

- `bash` 3.2+ (macOS compatible)
- `aws` CLI v2
- `terraform` >= 1.5
- `jq`
- An authenticated AWS session (`aws sso login --profile <p>`)

---

## Keeping up to date

```bash
terraform init -upgrade   # pulls the latest module from master
terraform apply           # re-chmod's the script if it changed
```

To pin to a specific version, change `?ref=master` to a tag:

```hcl
source = "git::https://github.com/wellcometrust/ncw-terraform-modules.git//AWS/unmanaged-resources-scanner?ref=v2.0.0"
```
