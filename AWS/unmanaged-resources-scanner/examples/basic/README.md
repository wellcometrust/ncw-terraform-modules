# Basic example – unmanaged-resources-scanner

A complete, copy-pasteable consumer setup for the
`unmanaged-resources-scanner` Terraform module. Use this as a template when
adding the scanner to a new infra repo.

## Files

- `main.tf` — wires up the module.
- `variables.tf` — defines the inputs the user should set per-repo.
- `terraform.tfvars.example` — example values; copy to `terraform.tfvars`
  and edit.

## How to use in your own repo

1. Copy the three files above into a folder of your choice (commonly
   `scans/` at the repo root).
2. Edit `main.tf` and replace the `source = "../../"` line with a real Git
   reference to your terraform-modules repo, for example:

   ```hcl
   source = "git::https://github.com/<your-org>/<your-modules>.git//unmanaged-resources-scanner?ref=v1.0.0"
   ```

3. `cp terraform.tfvars.example terraform.tfvars` and fill in the values
   for your AWS profile, account ID, repo name, and regions.
4. Run:

   ```bash
   terraform init
   terraform apply -auto-approve
   $(terraform output -raw scan_command)        # delivery mode (default)
   ```

   Or set `run_on_apply = true` in `terraform.tfvars` and the scan will
   execute during `terraform apply`.

## What you'll see

- `scan_command` — a ready-to-copy command that runs the scanner with all
  the flags you configured.
- `scan_context` — a small map echoing back the inputs (profile, account,
  repo, regions, mode) — useful for confirming you targeted the right
  account before running anything destructive.

## Output files

The scanner writes its reports to your current working directory:

- `unmanaged-resources-<account>-<timestamp>.md`
- `unmanaged-resources-<account>-<timestamp>.json` (if `json_output = true`)
- `check-unmanaged-output.md` / `.json`

