#!/usr/bin/env bash
# =============================================================================
# scan-unmanaged-resources.sh
#
# Account-aware scan wrapper. This script is shipped with the module so that
# the `all-unmanaged-resources.sh` wrapper works end-to-end in any mode
# (check-only, scan-only, or all).
#
# It delegates to check-unmanaged-resources.sh (the portable, generic scanner)
# and passes through any arguments. The ACCOUNT_ID environment variable (set
# by the wrapper or by Terraform) is used for labeling only — the check script
# auto-detects the real account from STS at runtime.
#
# If you need account-specific customisation (extra ignore patterns, custom
# resource checks, etc.), extend this script rather than editing the generic
# check-unmanaged-resources.sh.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check-unmanaged-resources.sh"

if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "[ERR] check-unmanaged-resources.sh not found at: $CHECK_SCRIPT" >&2
  exit 1
fi

echo "[INFO] scan-unmanaged-resources.sh: delegating to check-unmanaged-resources.sh"
[[ -n "${ACCOUNT_ID:-}" ]] && echo "[INFO] Target account: $ACCOUNT_ID"

exec "$CHECK_SCRIPT" "$@"

