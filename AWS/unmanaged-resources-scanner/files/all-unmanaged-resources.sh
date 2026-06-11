#!/usr/bin/env bash
# =============================================================================
# all-unmanaged-resources.sh
#
# Runs the unmanaged-resources scanners. By default it runs BOTH:
#   - check-unmanaged-resources.sh  (generic; works in any AWS account)
#   - scan-unmanaged-resources.sh   (optional account-specific scanner)
#
# Usage:
#   ./all-unmanaged-resources.sh [args]
#     --json                  # JSON output (passed to the check script)
#     --check-only            # Run only the generic check script (use in other accounts)
#     --scan-only             # Run only the account-specific scan script
#     --profile <name>        # AWS profile to use
#     --region <name>         # AWS region (repeatable; passed through)
#     --dir <path>            # Terraform stack directory (passed to check script)
#     --account <id>          # AWS account ID for labeling / interactive prompts
#     --expected-account <id> # Abort if STS reports a different account than this one
#     --account-name <name>   # Human-readable account name (e.g. wellcomedevelopers-prod)
#     --repo <name>           # Repo name (used in report filenames / Slack messages)
#     --setup <path>          # Path to your setup/login script
#     --strict-profile        # Abort unless an explicit AWS profile is set
#     --dry-run               # Verify auth + print banner, then exit WITHOUT scanning
#
# Requirements: scripts present in the same directory as this wrapper, and the
# user already logged in to AWS (e.g. via `aws sso login`).
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check-unmanaged-resources.sh"
SCAN_SCRIPT="$SCRIPT_DIR/scan-unmanaged-resources.sh"

# Parse args once. Wrapper-level flags are consumed here; the rest are
# forwarded to the child scripts.
CHECK_JSON=false
RUN_CHECK=true
RUN_SCAN=true
ARGS=()
expect_profile=false
expect_account=false
expect_setup=false
expect_expected_account=false
expect_repo=false
expect_account_name=false
ACCOUNT_ID="${ACCOUNT_ID:-}"
SETUP_SCRIPT="${SETUP_SCRIPT:-}"
EXPECTED_ACCOUNT="${EXPECTED_ACCOUNT:-}"
ACCOUNT_NAME="${ACCOUNT_NAME:-}"
REPO_NAME="${REPO_NAME:-}"
STRICT_PROFILE="${STRICT_PROFILE:-0}"
DRY_RUN="${DRY_RUN:-0}"
PROFILE_PROVIDED=false

for arg in "$@"; do
  if $expect_profile; then
    export AWS_PROFILE="$arg"
    PROFILE_PROVIDED=true
    ARGS+=("$arg")
    expect_profile=false
    continue
  fi
  if $expect_account; then
    ACCOUNT_ID="$arg"
    expect_account=false
    continue
  fi
  if $expect_setup; then
    SETUP_SCRIPT="$arg"
    expect_setup=false
    continue
  fi
  if $expect_expected_account; then
    EXPECTED_ACCOUNT="$arg"
    # Forward to child scripts too (check script enforces it as well).
    ARGS+=("--expected-account" "$arg")
    expect_expected_account=false
    continue
  fi
  if $expect_repo; then
    REPO_NAME="$arg"
    ARGS+=("--repo" "$arg")
    expect_repo=false
    continue
  fi
  if $expect_account_name; then
    ACCOUNT_NAME="$arg"
    ARGS+=("--account-name" "$arg")
    expect_account_name=false
    continue
  fi
  case "$arg" in
    --json)             CHECK_JSON=true ;;
    --check-only)       RUN_SCAN=false ;;
    --scan-only)        RUN_CHECK=false ;;
    --profile)          ARGS+=("$arg"); expect_profile=true ;;
    --account)          expect_account=true ;;
    --setup)            expect_setup=true ;;
    --expected-account) expect_expected_account=true ;;
    --repo)             expect_repo=true ;;
    --account-name)     expect_account_name=true ;;
    --strict-profile)   STRICT_PROFILE=1; ARGS+=("$arg") ;;
    --dry-run)          DRY_RUN=1; ARGS+=("$arg") ;;
    *)                  ARGS+=("$arg") ;;
  esac
done

# --- Required-args enforcement (mirrors the Terraform variable contract) ----
# When invoked from the Terraform module these are always set as env vars
# or CLI flags. When invoked manually we still require them so the
# scanner cannot accidentally run with missing context.
missing=()
[[ -z "${EXPECTED_ACCOUNT:-}" ]] && missing+=("--expected-account / EXPECTED_ACCOUNT")
[[ -z "${ACCOUNT_NAME:-}"     ]] && missing+=("--account-name / ACCOUNT_NAME")
[[ -z "${REPO_NAME:-}"        ]] && missing+=("--repo / REPO_NAME")
if ! $PROFILE_PROVIDED && [[ -z "${AWS_PROFILE:-}" ]]; then
  missing+=("--profile / AWS_PROFILE")
fi
# Regions: at least one --region must have been forwarded into ARGS.
have_region=false
for a in "${ARGS[@]:-}"; do
  [[ "$a" == "--region" ]] && have_region=true && break
done
$have_region || missing+=("--region (at least one)")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "[ERR] Missing required inputs:" >&2
  for m in "${missing[@]}"; do echo "[ERR]   * $m" >&2; done
  echo "[ERR] These inputs identify the AWS account / repo being scanned and" >&2
  echo "[ERR] are required to prevent scanning the wrong account. When using" >&2
  echo "[ERR] the Terraform module they are sourced from the equivalent variables." >&2
  exit 1
fi

# --- Interactive prompts (only when not supplied via flags or env vars) --------
# When run via Terraform local-exec, ACCOUNT_ID and SETUP_SCRIPT are set as
# environment variables. When run manually without flags, the user gets prompted.

if [[ -z "${ACCOUNT_ID:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "[INPUT] Enter the AWS account ID for this scan: " ACCOUNT_ID
    [[ -z "$ACCOUNT_ID" ]] && { echo "[ERR] Account ID cannot be empty." >&2; exit 1; }
  else
    echo "[ERR] ACCOUNT_ID not set and no interactive terminal available." >&2
    echo "[ERR] Pass --account <id> or set the ACCOUNT_ID environment variable." >&2
    exit 1
  fi
fi

if [[ -z "${SETUP_SCRIPT:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "[INPUT] Enter the path to your setup/login script (or press Enter to skip): " SETUP_SCRIPT
  fi
fi

# If no --expected-account was supplied on the CLI but ACCOUNT_ID was set
# interactively / via env, treat that as the expected account to enforce.
if [[ -z "${EXPECTED_ACCOUNT:-}" && -n "${ACCOUNT_ID:-}" ]]; then
  EXPECTED_ACCOUNT="$ACCOUNT_ID"
  ARGS+=("--expected-account" "$EXPECTED_ACCOUNT")
fi

export ACCOUNT_ID
export EXPECTED_ACCOUNT
export ACCOUNT_NAME
export REPO_NAME
SETUP_SCRIPT="${SETUP_SCRIPT:-}"
echo "[INFO] Target AWS account: $ACCOUNT_ID"
[[ -n "$EXPECTED_ACCOUNT" ]] && echo "[INFO] Expected AWS account (enforced): $EXPECTED_ACCOUNT"
[[ -n "$ACCOUNT_NAME" ]]     && echo "[INFO] Account name: $ACCOUNT_NAME"
[[ -n "$REPO_NAME" ]]        && echo "[INFO] Repo: $REPO_NAME"
[[ -n "$SETUP_SCRIPT" ]]     && echo "[INFO] Setup script: $SETUP_SCRIPT"

# Validate selected scripts exist & are executable
if $RUN_CHECK && [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "[ERR] Required script not found or not executable: $CHECK_SCRIPT" >&2
  exit 1
fi
if $RUN_SCAN && [[ ! -x "$SCAN_SCRIPT" ]]; then
  echo "[ERR] Required script not found or not executable: $SCAN_SCRIPT" >&2
  exit 1
fi

# Strict-profile guard: refuse to silently fall back to ambient credentials
# that may belong to an unrelated account.
if [[ "$STRICT_PROFILE" == "1" || "$STRICT_PROFILE" == "true" ]]; then
  if ! $PROFILE_PROVIDED && [[ -z "${AWS_PROFILE:-}" ]]; then
    echo "[ERR] --strict-profile set but no AWS profile provided." >&2
    echo "[ERR] Pass --profile <name> or export AWS_PROFILE before re-running." >&2
    exit 1
  fi
fi

export AWS_PROFILE="${AWS_PROFILE:-default}"

echo "[INFO] Using AWS_PROFILE: $AWS_PROFILE"
echo "[INFO] Verifying AWS credentials..."
IDENTITY_JSON="$(aws sts get-caller-identity --output json 2>/dev/null || true)"
if [[ -z "$IDENTITY_JSON" ]]; then
  echo "[ERR] Unable to authenticate to AWS with profile '$AWS_PROFILE'." >&2
  echo "[ERR] Log in first using your usual SSO flow, e.g.:" >&2
  echo "[ERR]   aws sso login --profile $AWS_PROFILE" >&2
  if [[ -n "$SETUP_SCRIPT" ]]; then
    echo "[ERR] Or run your setup script: $SETUP_SCRIPT" >&2
  fi
  exit 1
fi

# Enforce the expected-account guard early: if the ambient credentials point
# at a different AWS account than the operator declared, ABORT before any
# resource enumeration happens. This is the key portability fix - it
# prevents the scanner from silently scanning the wrong account when the
# module is consumed from a different repo.
if [[ -n "${EXPECTED_ACCOUNT:-}" ]]; then
  STS_ACCOUNT="$(printf '%s' "$IDENTITY_JSON" \
    | sed -nE 's/.*"Account"[[:space:]]*:[[:space:]]*"([0-9]+)".*/\1/p' | head -n1)"
  if [[ -z "$STS_ACCOUNT" ]]; then
    echo "[ERR] Unable to parse account ID from STS response." >&2
    exit 1
  fi
  if [[ "$STS_ACCOUNT" != "$EXPECTED_ACCOUNT" ]]; then
    echo "[ERR] Account mismatch: STS reports '$STS_ACCOUNT' but expected '$EXPECTED_ACCOUNT'." >&2
    echo "[ERR] Refusing to scan to avoid reporting on the wrong account." >&2
    echo "[ERR] Fix this by either:" >&2
    echo "[ERR]   * Logging in with the correct profile (aws sso login --profile <p>), or" >&2
    echo "[ERR]   * Updating var.aws_account_id in your consumer module." >&2
    exit 1
  fi
fi

# Pull the caller ARN out of the STS response for the banner. Done with
# sed rather than jq to avoid an extra dependency at this layer (jq is
# used by the child scripts, not this wrapper).
STS_CALLER_ARN="$(printf '%s' "$IDENTITY_JSON" \
  | sed -nE 's/.*"Arn"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n1)"
STS_ACCOUNT_DETECTED="$(printf '%s' "$IDENTITY_JSON" \
  | sed -nE 's/.*"Account"[[:space:]]*:[[:space:]]*"([0-9]+)".*/\1/p' | head -n1)"

# Always print a prominent context banner so the operator can verify
# WHICH AWS account / profile / repo is about to be scanned BEFORE any
# resource enumeration happens. This is deliberately impossible to miss.
echo ""
echo "################################################################################"
echo "#                       UNMANAGED RESOURCES SCANNER                            #"
echo "################################################################################"
echo "#  AWS Account (STS)  : ${STS_ACCOUNT_DETECTED}"
echo "#  Expected Account   : ${EXPECTED_ACCOUNT:-<not set>}"
echo "#  Account Name       : ${ACCOUNT_NAME:-<not set>}"
echo "#  Caller ARN         : ${STS_CALLER_ARN}"
echo "#  AWS Profile        : ${AWS_PROFILE}"
echo "#  Repo               : ${REPO_NAME:-<not set>}"
echo "#  Working dir (PWD)  : $(pwd)"
echo "#  Dry-run            : $([[ "$DRY_RUN" == "1" || "$DRY_RUN" == "true" ]] && echo YES || echo no)"
echo "#  Scripts dir        : $SCRIPT_DIR"
echo "################################################################################"
echo ""

if [[ "$DRY_RUN" == "1" || "$DRY_RUN" == "true" ]]; then
  echo "[INFO] DRY-RUN mode: skipping child scripts. No AWS resources will be enumerated."
  echo "[INFO] If the banner above looks correct, re-run with dry_run = false."
  exit 0
fi

echo "[INFO] AWS credentials verified."

if $RUN_CHECK; then
  echo ""
  echo "===== Running check-unmanaged-resources.sh ====="
  if $CHECK_JSON; then
    "$CHECK_SCRIPT" --json ${ARGS[@]+"${ARGS[@]}"} | tee check-unmanaged-output.json
  else
    "$CHECK_SCRIPT" ${ARGS[@]+"${ARGS[@]}"} | tee check-unmanaged-output.md
  fi
fi

if $RUN_SCAN; then
  echo ""
  echo "===== Running scan-unmanaged-resources.sh ====="
  "$SCAN_SCRIPT" ${ARGS[@]+"${ARGS[@]}"} | tee scan-unmanaged-output.md
fi

echo ""
echo "All scans complete."
$RUN_CHECK && echo "Check script output:   $(ls -1t check-unmanaged-output.* 2>/dev/null | head -n1)"
$RUN_SCAN  && echo "Scan script output:    $(ls -1t scan-unmanaged-output.md 2>/dev/null | head -n1)"
echo "You can now review the reports."
