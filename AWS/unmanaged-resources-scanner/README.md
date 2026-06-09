# unmanaged-resources-scanner

A reusable Terraform module that ships a set of bash scanners which compare
a Terraform stack's remote state against the live AWS account and report any
resources that exist in AWS but are **not** tracked in state.

The module is intentionally small: it bundles the scripts and exposes them
via outputs (and an optional `null_resource` trigger). It does **not**
provision AWS infrastructure.

> 💡 **Just want to use it?** Skip to [`examples/basic/`](./examples/basic/)
> for a complete copy-pasteable consumer setup (`main.tf`, `variables.tf`,
> `terraform.tfvars.example`). Copy those three files into your infra repo
> and edit `terraform.tfvars` with your profile / account / repo values.

## How it works

The scanner performs the following steps at runtime:

1. **Locates your Terraform stack** – auto-discovers the directory containing
   `.tf` files (or uses the `--dir` flag).
2. **Reads the remote state** – runs `terraform show -json` to extract every
   managed resource identifier (IDs, ARNs, names, tags, etc.).
3. **Reads CloudFormation stacks** – enumerates all active CFN stacks in the
   target regions and collects their `PhysicalResourceId` values so that
   StackSets-managed resources are not flagged as unmanaged.
4. **Scans the live AWS account** – queries 25+ resource types across all
   configured regions (EC2, VPC, IAM, S3, Lambda, RDS, ECS, KMS, etc.).
5. **Compares** – any resource found in AWS that is not in the Terraform state
   or CloudFormation is flagged as "unmanaged".
6. **Reports** – writes a Markdown report and optionally a JSON report.
   Can also post a summary to Slack.

### Ignore patterns

The scanner includes a built-in set of case-insensitive ignore patterns that
suppress common false positives:

- `firefly`, `tfstate`, `terraform-state`, `terraform-states` – state buckets
- `Softcat`, `softcat` – managed security partner resources
- `Key Pair` – EC2 key pairs (usually imported manually)
- `org-level`, `stacksets`, `QuickSetup`, `quicksetup` – AWS org-managed

The Terraform state backend bucket is also auto-discovered and added to the
ignore list.

### Interactive prompts

When the wrapper script (`all-unmanaged-resources.sh`) is run **manually** in
a terminal, it prompts for:

- **AWS Account ID** – used for labeling in the scan report
- **Setup script path** – shown in error messages if auth fails

These prompts are skipped when run via Terraform (the values are passed as
environment variables from the module's `account_id` and `setup_script`
variables). They can also be passed as CLI flags: `--account <id>` and
`--setup <path>`.

## What it provides

| Script | Purpose |
|--------|---------|
| `check-unmanaged-resources.sh` | Generic scanner. Auto-discovers account, profile, regions, and managed resources. Works in **any** AWS account. |
| `scan-unmanaged-resources.sh` | Account-aware wrapper that delegates to the check script. Extend this for per-account customisation. |
| `all-unmanaged-resources.sh` | Entry-point wrapper with `--check-only`, `--scan-only`, `--profile`, `--region`, `--dir`, `--json`, `--account`, `--setup` flags. |

## Requirements

On the machine running `terraform`:

- `bash` (3.2+ / macOS compatible)
- `aws` CLI v2
- `terraform` >= 1.0
- `jq`
- An authenticated AWS session (`aws sso login --profile <p>` or similar)

## Usage – consume from a Git source

```hcl
module "unmanaged_scan" {
  source = "git::https://github.com/<your-org>/<your-terraform-modules-repo>.git//unmanaged-resources-scanner?ref=v1.0.0"

  profile        = "my-account_AdministratorAccess"
  aws_account_id = "123456789012"
  account_id     = "123456789012"
  regions        = ["eu-west-1", "eu-west-2"]
  terraform_dir  = "./aws"
  setup_script   = "./scripts/setup.sh"
  run_on_apply   = true
  triggers       = { always = timestamp() }
}

output "scan_command" {
  value = module.unmanaged_scan.run_command
}
```

## How to run

### Option 1: Automatic (via Terraform apply)

Set `run_on_apply = true` and the scan runs every `terraform apply`:

```bash
cd scans/                        # or wherever your consumer lives
terraform init
terraform apply -auto-approve    # scan runs automatically
```

### Option 2: Manual (delivery mode)

Set `run_on_apply = false` (the default). Terraform delivers the scripts,
then you run them yourself:

```bash
terraform init
terraform apply -auto-approve
# Copy the command from the output:
$(terraform output -raw scan_command)
```

### Option 3: Run the script directly (no Terraform)

You can also run the script directly without Terraform at all:

```bash
./modules/unmanaged-resources-scanner/files/all-unmanaged-resources.sh \
  --check-only \
  --profile my-profile \
  --region eu-west-1 --region eu-west-2 \
  --dir ./aws \
  --account 123456789012 \
  --setup ./scripts/setup.sh
```

If you omit `--account` and `--setup`, you'll be prompted interactively.

## Variables

| Name                | Type           | Default       | Description |
|---------------------|----------------|---------------|-------------|
| `profile`           | `string`       | `""`          | AWS named profile to use. |
| `aws_account_id`    | `string`       | `""`          | AWS account ID (labeling only — scanner auto-detects at runtime). |
| `account_id`        | `string`       | `""`          | AWS account ID passed to the wrapper (avoids interactive prompt). |
| `setup_script`      | `string`       | `""`          | Path to setup/login script (shown in auth error messages). |
| `repo_name`         | `string`       | `""`          | Name of the infra repo being scanned (labeling only). |
| `regions`           | `list(string)` | `[]`          | Regions to scan. Empty = auto-detect from Terraform. |
| `terraform_dir`     | `string`       | `""`          | Terraform stack dir. Empty = auto-detect (`./aws`, `./terraform`, `.`). |
| `mode`              | `string`       | `check-only`  | `check-only` (portable), `scan-only` (account-specific), or `all`. |
| `run_on_apply`      | `bool`         | `false`       | Run the scanner during `terraform apply` via `null_resource`. |
| `json_output`       | `bool`         | `false`       | Pass `--json` to produce a machine-readable JSON report. |
| `working_dir`       | `string`       | `path.cwd`    | Where to write report files. |
| `triggers`          | `map(string)`  | `{}`          | Triggers for the `null_resource` (e.g. `{ always = timestamp() }`). |
| `slack_enabled`     | `bool`         | `true`        | If false, no Slack notification is sent. |
| `slack_webhook_url` | `string`       | `""`          | Slack webhook URL (marked `sensitive`). |

## Outputs

| Name                 | Description |
|----------------------|-------------|
| `scripts_dir`        | Absolute path to the shipped scripts directory. |
| `wrapper_path`       | Absolute path to `all-unmanaged-resources.sh`. |
| `check_script_path`  | Absolute path to `check-unmanaged-resources.sh`. |
| `scan_script_path`   | Absolute path to `scan-unmanaged-resources.sh`. |
| `run_command`        | Ready-to-copy shell command to invoke the scanner. |
| `context`            | Map of `profile`, `aws_account_id`, `repo_name`, `regions`, `terraform_dir`, `mode`. |

## Slack notifications

When the scan finishes, the check script will try to post a summary to Slack.
The webhook URL is resolved in this order:

1. `slack_webhook_url` variable on the module (highest priority).
2. `SLACK_WEBHOOK_URL` environment variable.
3. `slack_webhook_url = "..."` in `<terraform_dir>/terraform.tfvars`
   (auto-discovered from your stack).
4. Legacy fallbacks: `./terraform.tfvars`, `./aws/terraform.tfvars`.

Set `slack_enabled = false` to opt out entirely.

## CI example

```hcl
module "unmanaged_scan" {
  source = "git::https://github.com/<your-org>/<your-modules>.git//unmanaged-resources-scanner?ref=v1.0.0"

  run_on_apply   = true
  mode           = "check-only"
  json_output    = true
  account_id     = "123456789012"
  terraform_dir  = "${path.root}/aws"
  triggers       = { always = timestamp() }
  slack_enabled  = false
}
```

In a CI pipeline:

```bash
aws sso login --profile $PROFILE
terraform init
terraform apply -auto-approve -target=module.unmanaged_scan
cat unmanaged-resources-*.md
```

## Report output

The scanner writes its reports to `working_dir` (defaults to the current
working directory). Filenames:

- `unmanaged-resources-<account>-<timestamp>.md` – Markdown report
- `unmanaged-resources-<account>-<timestamp>.json` – JSON report (when `--json`)
- `check-unmanaged-output.md` / `.json` – tee'd stdout copy

## Notes

- The wrapper script verifies AWS credentials and aborts with a clear error
  if not logged in. The module does **not** attempt to log you in.
- All three scripts are shipped with the module. Any repo that pulls this
  module gets the same scanner logic and ignore patterns automatically.
- The module uses the `hashicorp/null` provider (>= 3.0) for `null_resource`.
- The module works on macOS (bash 3.2) and Linux.
