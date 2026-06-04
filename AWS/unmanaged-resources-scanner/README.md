# unmanaged-resources-scanner

A reusable Terraform module that ships a pair of bash scanners which compare
a Terraform stack's remote state against the live AWS account and report any
resources that exist in AWS but are **not** tracked in state.

The module is intentionally small: it bundles the scripts and exposes them
via outputs (and an optional `null_resource` trigger). It does **not**
provision AWS infrastructure.

> 💡 **Just want to use it?** Skip to [`examples/basic/`](./examples/basic/)
> for a complete copy-pasteable consumer setup (`main.tf`, `variables.tf`,
> `terraform.tfvars.example`). Copy those three files into your infra repo
> and edit `terraform.tfvars` with your profile / account / repo values.

## What it provides

- `check-unmanaged-resources.sh` – generic scanner. Auto-discovers the AWS
  account, profile, regions, and managed resources from any Terraform stack.
  Works in **any** AWS account.
- `all-unmanaged-resources.sh` – wrapper script with `--check-only`,
  `--scan-only`, `--profile`, `--region`, `--dir`, `--json` flags.

## Requirements

On the machine running `terraform`:

- `bash`, `aws` CLI v2, `terraform`, `jq`
- An authenticated AWS session (`aws sso login --profile <p>` or similar)

## Usage – consume from a Git source

```hcl
module "unmanaged_scan" {
  source = "git::https://github.com/<your-org>/<your-terraform-modules-repo>.git//unmanaged-resources-scanner?ref=v1.0.0"

  # All variables optional. Defaults: delivery-only, mode = check-only.
  profile       = "my-account_AdministratorAccess"
  regions       = ["eu-west-1", "eu-west-2"]
  terraform_dir = "./aws"
}

output "scan_command" {
  value = module.unmanaged_scan.run_command
}
```

After `terraform init` you can either:

1. Run the printed command manually:

   ```bash
   terraform output -raw scan_command | bash
   ```

2. Or have Terraform run it on every apply by setting `run_on_apply = true`
   (useful in CI).

## Variables

| Name             | Type           | Default       | Description |
|------------------|----------------|---------------|-------------|
| `profile`        | `string`       | `""`          | AWS named profile to use. |
| `aws_account_id` | `string`       | `""`          | AWS account ID being scanned (labeling only — scanner auto-detects at runtime). |
| `repo_name`      | `string`       | `""`          | Name of the infra repo being scanned (labeling only). |
| `regions`        | `list(string)` | `[]`          | Regions to scan. Empty = auto-detect from Terraform. |
| `terraform_dir`  | `string`       | `""`          | Terraform stack dir. Empty = auto-detect (`./aws`, `./terraform`, `.`). |
| `mode`           | `string`       | `check-only`  | `check-only` (portable), `scan-only` (NCW-specific), or `all`. |
| `run_on_apply`   | `bool`         | `false`       | Run the scanner during `terraform apply` via `null_resource`. |
| `json_output`    | `bool`         | `false`       | Pass `--json` to the check script. |
| `working_dir`    | `string`       | `path.cwd`    | Where to write report files. |
| `triggers`       | `map(string)`  | `{}`          | Triggers for the `null_resource` run (e.g. `{ always = timestamp() }`). |

## Outputs

| Name                 | Description |
|----------------------|-------------|
| `scripts_dir`        | Absolute path to the shipped scripts. |
| `wrapper_path`       | Absolute path to `all-unmanaged-resources.sh`. |
| `check_script_path`  | Absolute path to `check-unmanaged-resources.sh`. |
| `run_command`        | Ready-to-copy command line. |
| `context`            | Echo of `profile`, `aws_account_id`, `repo_name`, `regions`, `terraform_dir`, `mode`. |

## Example

A complete consumer setup (with `variables.tf`, `main.tf`, and a
`terraform.tfvars.example`) lives in [`examples/basic/`](./examples/basic/).
Copy those files into a new infra repo and edit `terraform.tfvars` with
your account/profile/repo values.

## CI example

```hcl
module "unmanaged_scan" {
  source = "git::https://github.com/<your-org>/<your-modules>.git//unmanaged-resources-scanner?ref=v1.0.0"

  run_on_apply  = true
  mode          = "check-only"
  json_output   = true
  terraform_dir = "${path.root}/aws"
  triggers      = { always = timestamp() }
}
```

In a CI pipeline:

```bash
aws sso login --profile $PROFILE
terraform init
terraform apply -auto-approve -target=module.unmanaged_scan
cat unmanaged-resources-*.md
```

## Notes

- The wrapper script verifies AWS credentials and aborts with a clear error
  if not logged in. The module does **not** attempt to log you in.
- The `scan-unmanaged-resources.sh` companion script (with hardcoded
  resource lists for AWS account `600392747173`) is **not** shipped in this
  module — only the portable `check-unmanaged-resources.sh` is. The wrapper
  defaults to `--check-only` so it works everywhere.
- Reports are written to `working_dir` (defaults to wherever you ran
  `terraform`). Output filenames:
  - `unmanaged-resources-<account>-<timestamp>.md`
  - `unmanaged-resources-<account>-<timestamp>.json` (when `--json`)
  - `check-unmanaged-output.md` / `.json`

