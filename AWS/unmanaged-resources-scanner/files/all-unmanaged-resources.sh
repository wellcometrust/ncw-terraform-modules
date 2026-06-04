#!/usr/bin/env bash
# =============================================================================
# all-unmanaged-resources.sh
#
# Runs the unmanaged-resources scanners. By default it runs BOTH:
#   - check-unmanaged-resources.sh  (generic; works in any AWS account)
#   - scan-unmanaged-resources.sh   (account-specific to 600392747173)
#
# Usage:
#   ./all-unmanaged-resources.sh [args]
#     --json         # JSON output (passed to the check script)
#     --check-only   # Run only the generic check script (use in other accounts)
#     --scan-only    # Run only the account-specific scan script
#     --profile ...  # AWS profile to use
#     --region ...   # AWS region (repeatable; passed through)
#     --dir <path>   # Terraform stack directory (passed to check script)
#
# Requirements: scripts present in the same directory as this wrapper, and the
# user already logged in to AWS (e.g. via aws/scripts/setup.sh).
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

for arg in "$@"; do
  if $expect_profile; then
    export AWS_PROFILE="$arg"
    ARGS+=("$arg")
    expect_profile=false
    continue
  fi
  case "$arg" in
    --json)       CHECK_JSON=true ;;
    --check-only) RUN_SCAN=false ;;
    --scan-only)  RUN_CHECK=false ;;
    --profile)    ARGS+=("$arg"); expect_profile=true ;;
    *)            ARGS+=("$arg") ;;
  esac
done

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
  echo "[ERR] Or (for this repo's NCW dev account): ./aws/scripts/setup.sh" >&2
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
  echo "[WARN] scan-unmanaged-resources.sh is hardcoded for AWS account 600392747173."
  echo "[WARN] If you are running this in a different account, use --check-only instead."
  "$SCAN_SCRIPT" ${ARGS[@]+"${ARGS[@]}"} | tee scan-unmanaged-output.md
fi

echo ""
echo "All scans complete."
$RUN_CHECK && echo "Check script output:   $(ls -1t check-unmanaged-output.* 2>/dev/null | head -n1)"
$RUN_SCAN  && echo "Scan script output:    $(ls -1t scan-unmanaged-output.md 2>/dev/null | head -n1)"
echo "You can now review the reports."

