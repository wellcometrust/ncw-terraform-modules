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

The scanner ships with a small set of **generic** case-insensitive ignore
patterns that suppress universally noisy resources:

- `tfstate`, `terraform-state`, `terraform-states` – state buckets
- `Key Pair` – EC2 key pairs (usually imported manually)
- `org-level`, `stacksets`, `QuickSetup`, `quicksetup` – AWS org-managed

The Terraform state backend bucket is also auto-discovered from your stack
and added to the ignore list.

Per-account / per-repo ignore patterns can be appended at runtime by
exporting `EXTRA_IGNORE_PATTERNS` (colon- or newline-separated) before
calling the wrapper, e.g.

```bash
EXTRA_IGNORE_PATTERNS="my-vendor:legacy-bucket" ./all-unmanaged-resources.sh ...
```

### Portability guards

To prevent the scanner from accidentally scanning the wrong AWS account or
the wrong Terraform stack when this module is consumed from a different
repo, several safeguards are enforced:

1. **`aws_account_id` is required when `run_on_apply = true`.** A Terraform
   `precondition` blocks the plan if it's missing. This guarantees the
   expected-account guard is always active.
2. **Expected-account guard.** The scanner aborts with a clear error if
   `aws sts get-caller-identity` reports a different account than
   `aws_account_id`. No resources are enumerated, no Slack message is sent.
3. **`profile` or `strict_profile` is required when `run_on_apply = true`.**
   A `precondition` blocks plans that have neither set, so the scanner
   cannot silently use whatever ambient credentials happen to be loaded.
4. **`terraform_dir` defaults to `path.root`** (the consumer's stack
   directory) instead of `path.cwd`. Set it explicitly only when your
   stack lives in a non-standard subdirectory.
5. **Loud context banner.** Before any AWS enumeration, the script prints
   a banner showing the resolved AWS account, caller ARN, profile (and
   how the profile was resolved), Terraform dir and repo. Impossible
   to miss in `terraform apply` output.
6. **State-sample diagnostic.** The check script prints the first 10
   managed identifiers it pulled out of `terraform show -json` so you
   can verify the right state was read. If the IDs look like resources
   from a different repo, you've pointed `--dir` at the wrong stack.
7. **`dry_run = true`** runs auth + the banner + state-sample, then
   exits BEFORE enumerating any AWS resources. Use this for the first
   `apply` in any new repo to confirm you're pointed at the right
   account before letting the scanner do anything.
8. **Slack webhook lookup is scoped to `terraform_dir`** (no fallback to
   `./terraform.tfvars` / `./aws/terraform.tfvars`) so reports cannot be
   posted to a different team's Slack channel.
9. **Report filenames are namespaced by repo**: `unmanaged-resources-<repo>-<account>-<timestamp>.md`.

### Recommended first-run recipe for any new repo

```hcl
module "unmanaged_scan" {
  source = "git::https://github.com/<your-org>/ncw-terraform-modules.git//AWS/unmanaged-resources-scanner?ref=<tag>"

  # REQUIRED identification - the module won't plan without these
  profile          = "wellcomedevelopers_AdministratorAccess"
  aws_account_id   = "111122223333"
  aws_account_name = "wellcomedevelopers-prod"
  repo_name        = "wellcomedevelopers-repo"
  regions          = ["eu-west-1", "eu-west-2"]

  # Recommended
  account_id   = "111122223333"   # skips interactive prompt
  run_on_apply = true
  dry_run      = true             # FIRST APPLY: print context, do not scan
}
```

Run `terraform apply`. The banner will be printed to the apply log:

```
################################################################################
#                       UNMANAGED RESOURCES SCANNER                            #
################################################################################
#  AWS Account (STS)  : 111122223333
#  Expected Account   : 111122223333
#  Account Name       : wellcomedevelopers-prod
#  Caller ARN         : arn:aws:sts::111122223333:assumed-role/...
#  AWS Profile        : wellcomedevelopers_AdministratorAccess
#  Repo               : wellcomedevelopers-repo
#  Working dir (PWD)  : /path/to/wellcomedevelopers-repo
#  Dry-run            : YES
################################################################################
```

If anything in that banner is wrong (especially `AWS Account (STS)`), **fix
your profile / SSO login before flipping `dry_run` off**. When the banner
matches your intent, set `dry_run = false` and re-apply to do the actual
scan.

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

The five identification inputs are **required** to prevent the scanner
from silently running against the wrong account / repo:

| Name                | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `profile`           | `string`       | **yes**  | AWS named profile (e.g. `"wellcomedevelopers_AdministratorAccess"`). |
| `aws_account_id`    | `string`       | **yes**  | 12-digit AWS account ID. Scanner aborts before touching AWS if STS reports a different account. |
| `aws_account_name`  | `string`       | **yes**  | Human-readable account name (e.g. `"wellcomedevelopers-prod"`). Shown in banner / report / Slack. |
| `repo_name`         | `string`       | **yes**  | Repo being scanned (e.g. `"wellcomedevelopers-repo"`). |
| `regions`           | `list(string)` | **yes**  | Regions to scan. At least one. |

Optional inputs:

| Name                | Type           | Default       | Description |
|---------------------|----------------|---------------|-------------|
| `terraform_dir`     | `string`       | `path.root`   | Terraform stack dir. Defaults to the consumer's root module. |
| `mode`              | `string`       | `check-only`  | `check-only`, `scan-only`, or `all`. |
| `run_on_apply`      | `bool`         | `false`       | Run the scanner during `terraform apply` via `null_resource`. |
| `dry_run`           | `bool`         | `false`       | Skip the scan; only print the context banner. |
| `json_output`       | `bool`         | `false`       | Also produce a JSON report. |
| `working_dir`       | `string`       | `path.root`   | Where to write report files. |
| `triggers`          | `map(string)`  | `{}`          | Triggers for the `null_resource`. |
| `slack_enabled`     | `bool`         | `true`        | If false, no Slack notification is sent. |
| `slack_webhook_url` | `string`       | `""`          | Slack webhook URL (marked `sensitive`). |
| `strict_profile`    | `bool`         | `false`       | If true, abort unless an explicit AWS profile is supplied. |
| `account_id`        | `string`       | `""`          | Convenience: passed to the wrapper to skip interactive prompts. |
| `setup_script`      | `string`       | `""`          | Path to setup/login script (shown in auth errors). |
| `install_readme`    | `bool`         | `true`        | Write a copy of this README into the consumer stack. |
| `readme_destination`| `string`       | `""`          | Path for the README copy. Defaults to `<path.root>/UNMANAGED_RESOURCES_SCANNER.md`. |
| `install_module_copy` | `bool`       | `false`       | Mirror the entire module into the consumer stack. |
| `module_copy_destination` | `string` | `""`          | Directory for the module copy. |
| `module_copy_exclude` | `list(string)` | `["examples/**", ".terraform/**", ".terraform.lock.hcl", "**/.DS_Store"]` | Patterns to exclude from the module copy. |

## Outputs

| Name                 | Description |
|----------------------|-------------|
| `scripts_dir`        | Absolute path to the shipped scripts directory. |
| `wrapper_path`       | Absolute path to `all-unmanaged-resources.sh`. |
| `check_script_path`  | Absolute path to `check-unmanaged-resources.sh`. |
| `scan_script_path`   | Absolute path to `scan-unmanaged-resources.sh`. |
| `run_command`        | Ready-to-copy shell command to invoke the scanner. |
| `context`            | Map of `profile`, `aws_account_id`, `repo_name`, `regions`, `terraform_dir`, `mode`, `strict_profile`. |
| `readme_path`        | Filesystem path of the README copy written into the consumer stack (empty when `install_readme = false`). |
| `module_copy_dir`    | Directory where the full module copy was written (empty when `install_module_copy = false`). |
| `module_copy_file_count` | Number of files written into the module copy directory. |

## Slack notifications

When the scan finishes, the check script will try to post a summary to Slack.
The webhook URL is resolved in this order:

1. `slack_webhook_url` variable on the module (highest priority).
2. `SLACK_WEBHOOK_URL` environment variable.
3. `slack_webhook_url = "..."` in `<terraform_dir>/terraform.tfvars`
   (auto-discovered from your stack).

Set `slack_enabled = false` to opt out entirely.

> ⚠️ The previous legacy fallbacks to `./terraform.tfvars` and
> `./aws/terraform.tfvars` (relative to the current working directory) have
> been **removed** so that running this module from one repo can no longer
> accidentally post a report into a different team's Slack channel.

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
- The module uses the `hashicorp/null` provider (>= 3.0) for `null_resource`
  and the `hashicorp/local` provider (>= 2.0) for writing the README copy.
- The module works on macOS (bash 3.2) and Linux.

## Local README copy

On every `terraform apply`, the module writes a verbatim copy of this README
into the consumer stack at `<path.root>/UNMANAGED_RESOURCES_SCANNER.md` (or
the path you set via `readme_destination`). The copy is prefixed with an
auto-generated banner warning not to edit it by hand. This means
operators can read the docs from inside their own repo without having to
navigate back to the modules repo.

Disable this behaviour with `install_readme = false`. The file is managed
by Terraform as a `local_file` resource, so it is removed on
`terraform destroy` and recreated when the README in the module changes.
Add the file (or a glob pattern) to your repo's `.gitignore` if you don't
want to commit the generated copy.

## Local copy of the entire module

If you also want the **whole module** (Terraform source, shell scripts,
README) mirrored into your repo so it can be reviewed without leaving the
codebase, set:

```hcl
module "unmanaged_scan" {
  source              = "git::https://github.com/<your-org>/ncw-terraform-modules.git//AWS/unmanaged-resources-scanner?ref=<tag>"
  install_module_copy = true
  # module_copy_destination = "${path.root}/vendor/unmanaged-resources-scanner"   # optional override
}
```

By default the copy is written to
`<path.root>/.unmanaged-resources-scanner-module/`. Each file is tracked
as its own `local_file` resource, so additions, deletions and edits in
the upstream module are picked up on the next `terraform apply`. The
copy is removed on `terraform destroy`.

An `AUTO_GENERATED.md` notice is dropped at the top of the directory so
anyone browsing it knows not to hand-edit. The `examples/` directory and
`.terraform/` are excluded by default - tweak the list via
`module_copy_exclude` if you want them too.

> ⚠️ The copy is intended for **review only**. Do not point a new
> `module "..." { source = "./.unmanaged-resources-scanner-module" }` at
> it - that would defeat the purpose of pulling a versioned module from
> the modules repo. Add the destination directory to `.gitignore` (or
> commit it deliberately if you want auditable diffs).

