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
#     --json         # JSON output (passed to the check script)
#     --check-only   # Run only the generic check script (use in other accounts)
#     --scan-only    # Run only the account-specific scan script
#     --profile ...  # AWS profile to use
#     --region ...   # AWS region (repeatable; passed through)
#     --dir <path>   # Terraform stack directory (passed to check script)
#     --account <id> # AWS account ID for the scan-only script
#     --setup <path> # Path to your setup/login script
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
ACCOUNT_ID="${ACCOUNT_ID:-}"
SETUP_SCRIPT="${SETUP_SCRIPT:-}"

for arg in "$@"; do
  if $expect_profile; then
    export AWS_PROFILE="$arg"
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
  case "$arg" in
    --json)       CHECK_JSON=true ;;
    --check-only) RUN_SCAN=false ;;
    --scan-only)  RUN_CHECK=false ;;
    --profile)    ARGS+=("$arg"); expect_profile=true ;;
    --account)    expect_account=true ;;
    --setup)      expect_setup=true ;;
    *)            ARGS+=("$arg") ;;
  esac
done

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

export ACCOUNT_ID
SETUP_SCRIPT="${SETUP_SCRIPT:-}"
echo "[INFO] Target AWS account: $ACCOUNT_ID"
[[ -n "$SETUP_SCRIPT" ]] && echo "[INFO] Setup script: $SETUP_SCRIPT"

# Validate selected scripts exist & are executable
if $RUN_CHECK && [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "[ERR] Required script not found or not executable: $CHECK_SCRIPT" >&2
  exit 1
fi
if $RUN_SCAN && [[ ! -x "$SCAN_SCRIPT" ]]; then
  echo "[ERR] Required script not found or not executable: $SCAN_SCRIPT" >&2
  exit 1
fi

export AWS_PROFILE="${AWS_PROFILE:-default}"

echo "[INFO] Using AWS_PROFILE: $AWS_PROFILE"
echo "[INFO] Verifying AWS credentials..."
if ! aws sts get-caller-identity --output json >/dev/null 2>&1; then
  echo "[ERR] Unable to authenticate to AWS with profile '$AWS_PROFILE'." >&2
  echo "[ERR] Log in first using your usual SSO flow, e.g.:" >&2
  echo "[ERR]   aws sso login --profile $AWS_PROFILE" >&2
  if [[ -n "$SETUP_SCRIPT" ]]; then
    echo "[ERR] Or run your setup script: $SETUP_SCRIPT" >&2
  fi
  exit 1
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
  echo "[WARN] scan-unmanaged-resources.sh is hardcoded for AWS account $ACCOUNT_ID."
  echo "[WARN] If you are running this in a different account, use --check-only instead."
  "$SCAN_SCRIPT" ${ARGS[@]+"${ARGS[@]}"} | tee scan-unmanaged-output.md
fi

echo ""
echo "All scans complete."
$RUN_CHECK && echo "Check script output:   $(ls -1t check-unmanaged-output.* 2>/dev/null | head -n1)"
$RUN_SCAN  && echo "Scan script output:    $(ls -1t scan-unmanaged-output.md 2>/dev/null | head -n1)"
echo "You can now review the reports."

