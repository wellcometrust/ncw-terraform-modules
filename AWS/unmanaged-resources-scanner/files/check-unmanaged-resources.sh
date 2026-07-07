#!/usr/bin/env bash
# =============================================================================
# check-unmanaged-resources.sh

# Generic, portable drift / unmanaged-resources scanner for any of our
# AWS infrastructure account repos.

# It performs NO hardcoding of account IDs, profile names, regions, bucket
# names or resource names. Everything is discovered at runtime from:

#   1. The Terraform configuration in the target directory (provider profile,
#      backend, region variables).
#   2. The Terraform remote state (resources that ARE managed).
#   3. STS get-caller-identity (account currently authenticated).
#   4. The AWS CLI (resources that EXIST in the account).

# It then prints / writes a report of every AWS resource it can see in the
# account that is NOT tracked in the remote state file.

# No credentials, secrets or account-specific identifiers are embedded.

# Usage:
#   ./check-unmanaged-resources.sh                       # use ./aws or .
#   ./check-unmanaged-resources.sh --dir ../aws
#   ./check-unmanaged-resources.sh --profile my-profile
#   ./check-unmanaged-resources.sh --region eu-west-1 --region eu-west-2
#   ./check-unmanaged-resources.sh --json                # JSON instead of MD

# Requirements: terraform >= 1.x, aws CLI v2, jq
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CLI args
# -----------------------------------------------------------------------------
TF_DIR=""
PROFILE_OVERRIDE=""
REGIONS=()
OUT_JSON=false
EXPECTED_ACCOUNT="${EXPECTED_ACCOUNT:-}"
REPO_NAME="${REPO_NAME:-}"
STRICT_PROFILE="${STRICT_PROFILE:-0}"

# Case-insensitive substrings that, if found in a resource ID or any of the
# detail fields, cause the finding to be silently ignored. Extend as needed.
# Generic patterns for Terraform-state buckets are included so any bucket
# whose name contains "tfstate" or "terraform-state" is automatically
# ignored across all our infra repos. Extra patterns can be appended at
# runtime via $EXTRA_IGNORE_PATTERNS (colon- or newline-separated). The
# actual backend bucket configured in `terraform.tf` is also auto-discovered
# and appended below.
IGNORE_PATTERNS=(
  "tfstate"
  "terraform-state"
  "terraform-states"
  "Key Pair"
  "org-level"
  "stacksets"
  "QuickSetup"
  "quicksetup"
  "Softcat"
  "softcat"
)

if [[ -n "${EXTRA_IGNORE_PATTERNS:-}" ]]; then
  # Allow ':' or newline-separated extra patterns.
  while IFS= read -r _p; do
    [[ -n "$_p" ]] && IGNORE_PATTERNS+=("$_p")
  done < <(printf '%s' "$EXTRA_IGNORE_PATTERNS" | tr ':' '\n')
fi

usage() {
  sed -n '2,30p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)              TF_DIR="$2"; shift 2 ;;
    --profile)          PROFILE_OVERRIDE="$2"; shift 2 ;;
    --region)           REGIONS+=("$2"); shift 2 ;;
    --json)             OUT_JSON=true; shift ;;
    --expected-account) EXPECTED_ACCOUNT="$2"; shift 2 ;;
    --repo)             REPO_NAME="$2"; shift 2 ;;
    --strict-profile)   STRICT_PROFILE=1; shift ;;
    -h|--help)          usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

# -----------------------------------------------------------------------------
# Colours / helpers
# -----------------------------------------------------------------------------
BOLD='\033[1m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
err()     { echo -e "${RED}[ERR ]${NC}  $*" >&2; }
section() { echo -e "\n${BOLD}=== $* ===${NC}" >&2; }

need() { command -v "$1" >/dev/null 2>&1 || { err "Missing required tool: $1"; exit 1; }; }
need terraform; need aws; need jq

aws_safe() { aws "$@" 2>/dev/null || true; }

# -----------------------------------------------------------------------------
# Locate Terraform directory
#
# When invoked from the Terraform module, TF_DIR is always set via --dir
# (anchored to the consumer's path.root). When invoked manually, we fall
# back to a CWD-relative search.
# -----------------------------------------------------------------------------
if [[ -z "$TF_DIR" ]]; then
  for cand in "." "./aws" "./terraform"; do
    if compgen -G "$cand/*.tf" > /dev/null; then TF_DIR="$cand"; break; fi
  done
fi
[[ -z "$TF_DIR" ]] && { err "Could not find a Terraform directory. Use --dir."; exit 1; }
TF_DIR="$(cd "$TF_DIR" && pwd)"
# Reject the bundled module dir itself - if the caller accidentally pointed
# us at .terraform/modules/<x>/files we'd end up with zero managed
# resources and flag the entire account.
if compgen -G "$TF_DIR/check-unmanaged-resources.sh" > /dev/null; then
  err "TF_DIR ($TF_DIR) appears to be the scanner's own module directory."
  err "Point --dir at your Terraform stack root, not the module."
  exit 1
fi
if ! compgen -G "$TF_DIR/*.tf" > /dev/null; then
  err "No *.tf files found in $TF_DIR - cannot read Terraform state."
  exit 1
fi
info "Terraform dir: $TF_DIR"

# -----------------------------------------------------------------------------
# Auto-discover the Terraform state bucket(s) from the backend config and add
# them to the ignore list (so the script never flags the bucket that holds its
# own state file).
# -----------------------------------------------------------------------------
while IFS= read -r b; do
  [[ -n "$b" ]] && IGNORE_PATTERNS+=("$b") && info "Ignoring TF state bucket: $b"
done < <(awk '
  /backend[[:space:]]*"s3"/ { in_backend=1 }
  in_backend && /bucket[[:space:]]*=/ {
    if (match($0, /"[^"]+"/)) {
      print substr($0, RSTART+1, RLENGTH-2)
    }
  }
  in_backend && /^\s*}/ { in_backend=0 }
' "$TF_DIR"/*.tf 2>/dev/null | sort -u)

# -----------------------------------------------------------------------------
# Detect AWS profile from provider.tf (or override / env)
# -----------------------------------------------------------------------------
PROFILE_SOURCE=""
if [[ -n "$PROFILE_OVERRIDE" ]]; then
  AWS_PROFILE="$PROFILE_OVERRIDE"
  PROFILE_SOURCE="--profile flag"
elif [[ -n "${AWS_PROFILE:-}" ]]; then
  PROFILE_SOURCE="AWS_PROFILE env var"
else
  AWS_PROFILE="$(grep -hE '^\s*profile\s*=' "$TF_DIR"/*.tf 2>/dev/null \
    | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  [[ -n "$AWS_PROFILE" ]] && PROFILE_SOURCE="auto-detected from $TF_DIR/*.tf"
fi
export AWS_PROFILE="${AWS_PROFILE:-}"

if [[ "$STRICT_PROFILE" == "1" || "$STRICT_PROFILE" == "true" ]]; then
  if [[ -z "$AWS_PROFILE" ]]; then
    err "--strict-profile set but no AWS profile detected (flag, env var, or provider.tf)."
    exit 1
  fi
fi

[[ -z "$AWS_PROFILE" ]] && warn "No AWS profile detected; relying on default credentials chain."
[[ -n "$AWS_PROFILE" ]] && info "AWS profile: $AWS_PROFILE ($PROFILE_SOURCE)"

# -----------------------------------------------------------------------------
# Verify credentials and detect account ID
# -----------------------------------------------------------------------------
section "Verifying AWS credentials"
IDENTITY="$(aws_safe sts get-caller-identity --output json)"
if [[ -z "$IDENTITY" ]]; then
  err "Unable to authenticate to AWS. Run your SSO login first."
  exit 1
fi
ACCOUNT_ID="$(echo "$IDENTITY" | jq -r '.Account')"
CALLER_ARN="$(echo "$IDENTITY" | jq -r '.Arn')"
info "Account: $ACCOUNT_ID"
info "Caller : $CALLER_ARN"

# Hard guard against scanning the wrong account when the operator declared
# an expected account ID. This is the central portability fix.
if [[ -n "${EXPECTED_ACCOUNT:-}" && "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]]; then
  err "Account mismatch: STS reports '$ACCOUNT_ID' but expected '$EXPECTED_ACCOUNT'."
  err "Refusing to scan to avoid reporting on the wrong account."
  err "Log in with the correct profile or update var.aws_account_id."
  exit 1
fi

# -----------------------------------------------------------------------------
# Detect regions
#   - explicit --region flags win
#   - otherwise pull region values out of the provider.tf blocks
#   - otherwise fall back to the current default region
# -----------------------------------------------------------------------------
if [[ ${#REGIONS[@]} -eq 0 ]]; then
  # Look for region = "literal" (skip var.* references)
  while IFS= read -r r; do
    [[ -n "$r" ]] && REGIONS+=("$r")
  done < <(grep -hE '^\s*region\s*=\s*"' "$TF_DIR"/*.tf 2>/dev/null \
            | sed -E 's/.*"([^"]+)".*/\1/' | sort -u)

  # Resolve region variables (region = var.xxx) via terraform.tfvars
  if compgen -G "$TF_DIR/terraform.tfvars" > /dev/null; then
    while IFS= read -r r; do
      [[ -n "$r" ]] && REGIONS+=("$r")
    done < <(grep -hE '^[A-Za-z_][A-Za-z0-9_-]*\s*=\s*"[a-z]{2}-[a-z]+-[0-9]"' \
              "$TF_DIR/terraform.tfvars" 2>/dev/null \
              | sed -E 's/.*"([^"]+)".*/\1/' | sort -u)
  fi
fi
if [[ ${#REGIONS[@]} -eq 0 ]]; then
  DEFAULT_REGION="$(aws configure get region 2>/dev/null || echo eu-west-1)"
  REGIONS+=("$DEFAULT_REGION")
fi
  # Deduplicate (POSIX-compatible)
  deduped_regions_set=""
  deduped_regions=()
  for region in "${REGIONS[@]}"; do
    case ",$deduped_regions_set," in
      *,"$region",*) continue ;;
      *) deduped_regions+=("$region"); deduped_regions_set+="${region}," ;;
    esac
  done
  REGIONS=("${deduped_regions[@]}")
info "Regions: ${REGIONS[*]}"

# -----------------------------------------------------------------------------
# Pull Terraform state and build a set of managed identifiers
# -----------------------------------------------------------------------------
section "Reading Terraform state"

pushd "$TF_DIR" >/dev/null
if [[ ! -d .terraform ]]; then
  info "Running 'terraform init -backend=true' (read-only state access)..."
  terraform init -input=false -lock=false >&2 || {
    err "terraform init failed"; popd >/dev/null; exit 1;
  }
fi

TF_JSON="$(mktemp)"
trap 'rm -f "$TF_JSON"' EXIT

if ! terraform show -json > "$TF_JSON" 2>/dev/null; then
  err "Failed to read terraform state. Check backend access."
  popd >/dev/null; exit 1
fi
popd >/dev/null

RES_COUNT=$(jq '[.values.root_module | .. | .resources? // empty | .[]] | length' "$TF_JSON")
info "Managed resources in state: $RES_COUNT"

# Build a newline-delimited set of every value we might see come back
# from the AWS CLI: id, arn, name, bucket, key_name, alias, function_name,
# tags.Name etc. We dump them all and grep against this set later.
MANAGED_IDS="$(mktemp)"
trap 'rm -f "$TF_JSON" "$MANAGED_IDS"' EXIT

jq -r '
  [.. | objects | select(.type? and .values?) ]
  | .[]
  | .values
  | [ .id?, .arn?, .name?, .bucket?, .key_name?, .function_name?,
      .role_name?, .user_name?, .group_name?, .policy_name?, .alias?,
      .alias_name?, .log_group_name?, .parameter_name?, .schedule_name?,
      .detector_id?, .repository_name?, .cluster_name?, .topic_arn?,
      .queue_url?, .vpc_id?, .subnet_id?, .security_group_id?,
      .internet_gateway_id?, .route_table_id?, .network_acl_id?,
      .volume_id?, .image_id?, .snapshot_id?, .public_ip?, .allocation_id?,
      .load_balancer_arn?, .target_group_arn?,
      ((.tags? // {}).Name? // empty)
    ]
  | map(select(. != null and . != ""))
  | .[]
' "$TF_JSON" 2>/dev/null | sort -u > "$MANAGED_IDS"

MANAGED_COUNT=$(wc -l < "$MANAGED_IDS" | tr -d ' ')
info "Distinct managed identifiers extracted: $MANAGED_COUNT"

# Load managed IDs into a single newline-delimited string and do membership
# tests with bash substring matching. This avoids spawning `grep -Fxq` for
# every candidate and works on bash 3.2 (macOS) which lacks `declare -A`.
MANAGED_BLOB=$'\n'"$(cat "$MANAGED_IDS")"$'\n'

# -----------------------------------------------------------------------------
# CloudFormation: anything provisioned via a CFN stack is "managed" by AWS
# (not by us / not by Terraform), so append every PhysicalResourceId of every
# active stack across the scanned regions to the managed set.

# This means:
#   * StackSets-created resources (which AWS tags with aws:cloudformation:*)
#     no longer show up as unmanaged.
#   * Per-account stacks (e.g. SecurityHub, GuardDuty defaults, Config
#     recorders) are filtered out automatically.
# -----------------------------------------------------------------------------
section "Reading CloudFormation stack resources"
CFN_IDS_FILE="$(mktemp)"
trap 'rm -f "$TF_JSON" "$MANAGED_IDS" "$CFN_IDS_FILE"' EXIT

# We don't know which regions to walk for CFN until later (REGIONS array is
# already populated above). Build a deduped set of all PhysicalResourceIds.
CFN_STACK_COUNT=0
for R in "${REGIONS[@]}"; do
  while IFS= read -r stack; do
    [[ -z "$stack" || "$stack" == "None" ]] && continue
    CFN_STACK_COUNT=$((CFN_STACK_COUNT + 1))
    aws_safe cloudformation list-stack-resources --region "$R" --stack-name "$stack" \
      --query "StackResourceSummaries[].PhysicalResourceId" --output json \
      | jq -r '.[]?' >> "$CFN_IDS_FILE"
  done < <(aws_safe cloudformation list-stacks --region "$R" \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE IMPORT_COMPLETE \
    --query "StackSummaries[].StackName" --output json | jq -r '.[]?')
done

CFN_IDS_COUNT=$(sort -u "$CFN_IDS_FILE" | grep -cv '^$' || true)
info "CloudFormation stacks scanned: $CFN_STACK_COUNT"
info "Distinct CloudFormation-managed identifiers: $CFN_IDS_COUNT"

# Append CFN PhysicalResourceIds to MANAGED_BLOB so is_managed() picks them up.
if [[ "$CFN_IDS_COUNT" -gt 0 ]]; then
  MANAGED_BLOB+="$(sort -u "$CFN_IDS_FILE")"$'\n'
fi

# Membership test: returns 0 if ANY of the provided candidate strings is
# present (exact line match) in the managed-id set.
is_managed() {
  local c
  for c in "$@"; do
    [[ -z "$c" || "$c" == "null" ]] && continue
    [[ "$MANAGED_BLOB" == *$'\n'"$c"$'\n'* ]] && return 0
  done
  return 1
}

# -----------------------------------------------------------------------------
# Reporting
# -----------------------------------------------------------------------------
TS="$(date -u +%Y%m%d-%H%M%S)"

# Derive a repo identifier so reports from different consumer repos don't
# collide on disk. Preference order: --repo flag / $REPO_NAME env var,
# then `git rev-parse --show-toplevel` from inside TF_DIR, then "unknown".
if [[ -z "${REPO_NAME:-}" ]]; then
  REPO_NAME="$( (cd "$TF_DIR" && git rev-parse --show-toplevel 2>/dev/null) | xargs -I{} basename {} 2>/dev/null || true )"
fi
REPO_NAME="${REPO_NAME:-unknown}"
# Sanitise for filenames (alnum, dash, underscore only).
REPO_SLUG="$(printf '%s' "$REPO_NAME" | tr -c 'A-Za-z0-9_-' '-' | sed 's/-\{2,\}/-/g; s/^-//; s/-$//')"
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="unknown"

REPORT_MD="unmanaged-resources-${REPO_SLUG}-${ACCOUNT_ID}-${TS}.md"
REPORT_JSON="unmanaged-resources-${REPO_SLUG}-${ACCOUNT_ID}-${TS}.json"

{
  echo "# Unmanaged AWS Resources Report"
  echo "- **Repo:** \`$REPO_NAME\`"
  echo "- **Account:** \`$ACCOUNT_ID\`"
  echo "- **Caller:** \`$CALLER_ARN\`"
  echo "- **Regions scanned:** ${REGIONS[*]}"
  echo "- **Terraform dir:** \`$TF_DIR\`"
  echo "- **Managed resources in state:** $RES_COUNT"
  echo "- **Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
  echo "Resources listed here exist in the AWS account but are NOT tracked in"
  echo "the Terraform remote state."
  echo ""
} > "$REPORT_MD"

FINDINGS_JSON="["
FIRST=true
COUNT=0

record() {
  local category="$1" region="$2" id="$3" detail="$4"
  # Apply ignore filter (case-insensitive substring match against id + detail)
  local haystack
  haystack="$(printf '%s %s %s' "$category" "$id" "$detail" | tr '[:upper:]' '[:lower:]')"
  for pat in "${IGNORE_PATTERNS[@]}"; do
    local lpat
    lpat="$(printf '%s' "$pat" | tr '[:upper:]' '[:lower:]')"
    if [[ "$haystack" == *"$lpat"* ]]; then
      info "  IGNORED (matches '$pat'): [$category] $id"
      return 0
    fi
  done
  COUNT=$((COUNT + 1))
  warn "UNMANAGED [$category] ($region) $id  $detail"
  printf '| %s | %s | `%s` | %s |\n' \
    "$category" "$region" "$id" "$detail" >> "$REPORT_MD"
  local j
  j=$(jq -nc --arg c "$category" --arg r "$region" --arg i "$id" --arg d "$detail" \
    '{category:$c, region:$r, id:$i, detail:$d}')
  if $FIRST; then FINDINGS_JSON+="$j"; FIRST=false
  else FINDINGS_JSON+=",$j"; fi
}

start_table() {
  {
    echo ""
    echo "## $1"
    echo ""
    echo "| Category | Region | ID | Detail |"
    echo "|---|---|---|---|"
  } >> "$REPORT_MD"
}

# (TSV output from jq is unquoted/tab-separated, so no per-field stripping
# is required — fields are read directly via `IFS='|' read -r ...`.)

# -----------------------------------------------------------------------------
# Scanners (only "name-able", customer-mutable resources – we deliberately
# skip default VPC/SG/NACL and AWS-managed IAM/log groups).
# -----------------------------------------------------------------------------
scan_region() {
  local R="$1"
  section "Region $R"

  # Discover the default VPC for this region so we can skip ALL resources
  # that belong to it (subnets, route tables, IGW, NACL, SGs). AWS-created
  # default networking is not customer-managed and only adds noise.
  local DEFAULT_VPC
  DEFAULT_VPC="$(aws_safe ec2 describe-vpcs --region "$R" \
    --filters "Name=is-default,Values=true" \
    --query "Vpcs[0].VpcId" --output text 2>/dev/null)"
  [[ "$DEFAULT_VPC" == "None" || "$DEFAULT_VPC" == "null" ]] && DEFAULT_VPC=""
  [[ -n "$DEFAULT_VPC" ]] && info "Default VPC in $R: $DEFAULT_VPC (its resources will be ignored)"

  # ----- EC2 instances ----------------------------------------------------
  start_table "EC2 Instances ($R)"
  while IFS='|' read -r id name state itype; do
    [[ -z "$id" || "$state" == "terminated" ]] && continue
    if ! is_managed "$id" "$name"; then
      record "EC2 Instance" "$R" "$id" "Name=$name State=$state Type=$itype"
    fi
  done < <(aws_safe ec2 describe-instances --region "$R" \
    --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name']|[0].Value,State.Name,InstanceType]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Security groups (non-default) -----------------------------------
  start_table "Security Groups ($R)"
  while IFS='|' read -r sgid sgname vpcid; do
    [[ -z "$sgid" || "$sgname" == "default" ]] && continue
    [[ -n "$DEFAULT_VPC" && "$vpcid" == "$DEFAULT_VPC" ]] && continue
    if ! is_managed "$sgid" "$sgname"; then
      record "Security Group" "$R" "$sgid" "Name=$sgname VPC=$vpcid"
    fi
  done < <(aws_safe ec2 describe-security-groups --region "$R" \
    --query "SecurityGroups[].[GroupId,GroupName,VpcId]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- VPCs (non-default) ----------------------------------------------
  start_table "VPCs ($R)"
  while IFS='|' read -r vpcid vname cidr isdef; do
    [[ -z "$vpcid" || "$isdef" == "true" ]] && continue
    if ! is_managed "$vpcid" "$vname"; then
      record "VPC" "$R" "$vpcid" "Name=$vname CIDR=$cidr"
    fi
  done < <(aws_safe ec2 describe-vpcs --region "$R" \
    --query "Vpcs[].[VpcId,Tags[?Key=='Name']|[0].Value,CidrBlock,IsDefault]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Subnets ----------------------------------------------------------
  start_table "Subnets ($R)"
  while IFS='|' read -r snid snname cidr vpcid; do
    [[ -z "$snid" ]] && continue
    [[ -n "$DEFAULT_VPC" && "$vpcid" == "$DEFAULT_VPC" ]] && continue
    if ! is_managed "$snid" "$snname"; then
      record "Subnet" "$R" "$snid" "Name=$snname CIDR=$cidr VPC=$vpcid"
    fi
  done < <(aws_safe ec2 describe-subnets --region "$R" \
    --query "Subnets[].[SubnetId,Tags[?Key=='Name']|[0].Value,CidrBlock,VpcId]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Route tables -----------------------------------------------------
      start_table "Route Tables ($R)"
      while IFS='|' read -r rtid rtname vpcid main; do
        [[ -z "$rtid" ]] && continue
        [[ -n "$DEFAULT_VPC" && "$vpcid" == "$DEFAULT_VPC" ]] && continue
        [[ "$main" == "true" ]] && continue  # Exclude Main=yes route tables
        if ! is_managed "$rtid" "$rtname"; then
          record "Route Table" "$R" "$rtid" "Name=$rtname VPC=$vpcid"
        fi
      done < <(aws_safe ec2 describe-route-tables --region "$R" \
        --query "RouteTables[].[RouteTableId,Tags[?Key=='Name']|[0].Value,VpcId,Associations]" \
                --output json | jq -r '.[] | [ (.[0] // ""), (.[1] // ""), (.[2] // ""), ( (.[3] // []) | if type=="array" then (.[0].Main // "") else "" end ) ] | map(tostring) | map(if . == null then "" else tostring end) | join("|")')

  # ----- Internet gateways -----------------------------------------------
  start_table "Internet Gateways ($R)"
  while IFS='|' read -r igid igname attvpc; do
    [[ -z "$igid" ]] && continue
    [[ -n "$DEFAULT_VPC" && "$attvpc" == "$DEFAULT_VPC" ]] && continue
    if ! is_managed "$igid" "$igname"; then
      record "Internet Gateway" "$R" "$igid" "Name=$igname VPC=$attvpc"
    fi
  done < <(aws_safe ec2 describe-internet-gateways --region "$R" \
    --query "InternetGateways[].[InternetGatewayId,Tags[?Key=='Name']|[0].Value,Attachments[0].VpcId]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Network ACLs (non-default) --------------------------------------
  start_table "Network ACLs ($R)"
  while IFS='|' read -r nid nname vpcid isdef; do
    [[ -z "$nid" || "$isdef" == "true" ]] && continue
    [[ -n "$DEFAULT_VPC" && "$vpcid" == "$DEFAULT_VPC" ]] && continue
    if ! is_managed "$nid" "$nname"; then
      record "Network ACL" "$R" "$nid" "Name=$nname VPC=$vpcid"
    fi
  done < <(aws_safe ec2 describe-network-acls --region "$R" \
    --query "NetworkAcls[].[NetworkAclId,Tags[?Key=='Name']|[0].Value,VpcId,IsDefault]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- VPC endpoints ----------------------------------------------------
  start_table "VPC Endpoints ($R)"
  while IFS='|' read -r eid ename svc vpcid; do
    [[ -z "$eid" ]] && continue
    if ! is_managed "$eid" "$ename"; then
      record "VPC Endpoint" "$R" "$eid" "Name=$ename Service=$svc VPC=$vpcid"
    fi
  done < <(aws_safe ec2 describe-vpc-endpoints --region "$R" \
    --query "VpcEndpoints[?State!='deleted'].[VpcEndpointId,Tags[?Key=='Name']|[0].Value,ServiceName,VpcId]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- EBS volumes (named only; root vols unnamed) ---------------------
  start_table "EBS Volumes ($R)"
  while IFS='|' read -r vid vname vstate vsize vtype; do
    [[ -z "$vid" || -z "$vname" || "$vname" == "null" ]] && continue
    if ! is_managed "$vid" "$vname"; then
      record "EBS Volume" "$R" "$vid" "Name=$vname State=$vstate Size=${vsize}GB Type=$vtype"
    fi
  done < <(aws_safe ec2 describe-volumes --region "$R" \
    --filters "Name=status,Values=in-use,available" \
    --query "Volumes[].[VolumeId,Tags[?Key=='Name']|[0].Value,State,Size,VolumeType]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Elastic IPs ------------------------------------------------------
  start_table "Elastic IPs ($R)"
  while IFS='|' read -r alloc eip ename assoc; do
    [[ -z "$alloc" ]] && continue
    if ! is_managed "$alloc" "$eip" "$ename"; then
      record "Elastic IP" "$R" "$eip" "AllocationId=$alloc Name=$ename Assoc=${assoc:-none}"
    fi
  done < <(aws_safe ec2 describe-addresses --region "$R" \
    --query "Addresses[].[AllocationId,PublicIp,Tags[?Key=='Name']|[0].Value,AssociationId]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Key pairs --------------------------------------------------------
  start_table "Key Pairs ($R)"
  while IFS='|' read -r kname ktype kcreated; do
    [[ -z "$kname" ]] && continue
    if ! is_managed "$kname"; then
      record "Key Pair" "$R" "$kname" "Type=$ktype Created=$kcreated"
    fi
  done < <(aws_safe ec2 describe-key-pairs --region "$R" \
    --query "KeyPairs[].[KeyName,KeyType,CreateTime]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Load balancers (ALB/NLB + classic) ------------------------------
  start_table "Load Balancers ($R)"
  while IFS='|' read -r lbname lbarn lbtype lbstate; do
    [[ -z "$lbname" ]] && continue
    if ! is_managed "$lbarn" "$lbname"; then
      record "Load Balancer" "$R" "$lbname" "Type=$lbtype State=$lbstate"
    fi
  done < <(aws_safe elbv2 describe-load-balancers --region "$R" \
    --query "LoadBalancers[].[LoadBalancerName,LoadBalancerArn,Type,State.Code]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')
  while read -r clb; do
    [[ -z "$clb" ]] && continue
    if ! is_managed "$clb"; then
      record "Classic LB" "$R" "$clb" ""
    fi
  done < <(aws_safe elb describe-load-balancers --region "$R" \
    --query "LoadBalancerDescriptions[].LoadBalancerName" --output json | jq -r '.[]?')

  # ----- KMS aliases (skip alias/aws/*) ----------------------------------
  start_table "KMS Keys ($R)"
  while IFS='|' read -r alias keyid; do
    [[ -z "$alias" ]] && continue
    if ! is_managed "$alias" "$keyid"; then
      record "KMS Key" "$R" "$alias" "KeyId=$keyid"
    fi
  done < <(aws_safe kms list-aliases --region "$R" \
    --query "Aliases[?starts_with(AliasName,'alias/') && !starts_with(AliasName,'alias/aws/')].[AliasName,TargetKeyId]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- CloudWatch log groups (skip /aws/*) -----------------------------
  start_table "CloudWatch Log Groups ($R)"
  while IFS='|' read -r lg ret; do
    [[ -z "$lg" ]] && continue
    [[ "$lg" == /aws/* ]] && continue
    if ! is_managed "$lg"; then
      record "Log Group" "$R" "$lg" "Retention=${ret:-Never}"
    fi
  done < <(aws_safe logs describe-log-groups --region "$R" \
    --query "logGroups[].[logGroupName,retentionInDays]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- SSM parameters (skip /aws/*) ------------------------------------
  start_table "SSM Parameters ($R)"
  while IFS='|' read -r pn pt pmod; do
    [[ -z "$pn" ]] && continue
    [[ "$pn" == /aws/* ]] && continue
    if ! is_managed "$pn"; then
      record "SSM Param" "$R" "$pn" "Type=$pt LastModified=$pmod"
    fi
  done < <(aws_safe ssm describe-parameters --region "$R" \
    --query "Parameters[].[Name,Type,LastModifiedDate]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- Scheduler schedules ---------------------------------------------
  start_table "EventBridge Scheduler Schedules ($R)"
  while IFS='|' read -r sn sg sst; do
    [[ -z "$sn" ]] && continue
    if ! is_managed "$sn"; then
      record "Schedule" "$R" "$sn" "Group=$sg State=$sst"
    fi
  done < <(aws_safe scheduler list-schedules --region "$R" \
    --query "Schedules[].[Name,GroupName,State]" --output json | jq -r '.[]? | map(if . == null then "" else tostring end) | join("|")')

  # ----- Lambda functions -------------------------------------------------
  start_table "Lambda Functions ($R)"
  while IFS='|' read -r fn rt mod; do
    [[ -z "$fn" ]] && continue
    if ! is_managed "$fn"; then
      record "Lambda" "$R" "$fn" "Runtime=$rt LastModified=$mod"
    fi
  done < <(aws_safe lambda list-functions --region "$R" \
    --query "Functions[].[FunctionName,Runtime,LastModified]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- RDS instances ----------------------------------------------------
  start_table "RDS Instances ($R)"
  while IFS='|' read -r dbid dbc eng st; do
    [[ -z "$dbid" ]] && continue
    if ! is_managed "$dbid"; then
      record "RDS" "$R" "$dbid" "Class=$dbc Engine=$eng Status=$st"
    fi
  done < <(aws_safe rds describe-db-instances --region "$R" \
    --query "DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]" \
    --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- SNS topics -------------------------------------------------------
  start_table "SNS Topics ($R)"
  while read -r tarn; do
    [[ -z "$tarn" ]] && continue
    tname="${tarn##*:}"
    if ! is_managed "$tarn" "$tname"; then
      record "SNS Topic" "$R" "$tname" "ARN=$tarn"
    fi
  done < <(aws_safe sns list-topics --region "$R" \
    --query "Topics[].TopicArn" --output json | jq -r '.[]?')

  # ----- SQS queues -------------------------------------------------------
  start_table "SQS Queues ($R)"
  while read -r qurl; do
    [[ -z "$qurl" ]] && continue
    qname="${qurl##*/}"
    if ! is_managed "$qurl" "$qname"; then
      record "SQS Queue" "$R" "$qname" "URL=$qurl"
    fi
  done < <(aws_safe sqs list-queues --region "$R" \
    --query "QueueUrls" --output json | jq -r '.[]?')

  # ----- Secrets Manager (names only; never dump values) -----------------
  start_table "Secrets Manager ($R)"
  while IFS='|' read -r sn sarn smod; do
    [[ -z "$sn" ]] && continue
    if ! is_managed "$sn" "$sarn"; then
      record "Secret" "$R" "$sn" "LastChanged=$smod"
    fi
  done < <(aws_safe secretsmanager list-secrets --region "$R" \
    --query "SecretList[].[Name,ARN,LastChangedDate]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  # ----- ECR --------------------------------------------------------------
  start_table "ECR Repositories ($R)"
  while IFS='|' read -r rn ru; do
    [[ -z "$rn" ]] && continue
    if ! is_managed "$rn" "$ru"; then
      record "ECR Repo" "$R" "$rn" "URI=$ru"
    fi
  done < <(aws_safe ecr describe-repositories --region "$R" \
    --query "repositories[].[repositoryName,repositoryUri]" --output json | jq -r '.[]? | map(if . == null then "" else tostring end) | join("|")')

  # ----- ECS clusters -----------------------------------------------------
  start_table "ECS Clusters ($R)"
  while read -r carn; do
    [[ -z "$carn" ]] && continue
    cname="${carn##*/}"
    if ! is_managed "$carn" "$cname"; then
      record "ECS Cluster" "$R" "$cname" "ARN=$carn"
    fi
  done < <(aws_safe ecs list-clusters --region "$R" \
    --query "clusterArns" --output json | jq -r '.[]?')
}

# -----------------------------------------------------------------------------
# Global (non-regional) scanners – IAM and S3
# -----------------------------------------------------------------------------
scan_global() {
  section "Global resources"

  start_table "S3 Buckets (global)"
  while read -r bucket; do
    [[ -z "$bucket" ]] && continue
    if ! is_managed "$bucket"; then
      brg=$(aws_safe s3api get-bucket-location --bucket "$bucket" \
            --query "LocationConstraint" --output text)
      record "S3 Bucket" "global" "$bucket" "Region=${brg:-us-east-1}"
    fi
  done < <(aws_safe s3api list-buckets --query "Buckets[].Name" --output json | jq -r '.[]?')

  start_table "IAM Roles (customer)"
  while IFS='|' read -r rn rc; do
    [[ -z "$rn" ]] && continue
    # Skip AWS service-linked / reserved roles
    [[ "$rn" == AWS* || "$rn" == aws-* || "$rn" == AWSReserved* ]] && continue
    # AWS service-linked roles always have a path starting with /aws-service-role/
    rpath=$(aws_safe iam get-role --role-name "$rn" --query "Role.Path" --output text)
    [[ "$rpath" == /aws-service-role/* ]] && continue
    if ! is_managed "$rn"; then
      record "IAM Role" "global" "$rn" "Created=$rc"
    fi
  done < <(aws_safe iam list-roles --query "Roles[].[RoleName,CreateDate]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  start_table "IAM Users"
  while IFS='|' read -r un uc; do
    [[ -z "$un" ]] && continue
    if ! is_managed "$un"; then
      record "IAM User" "global" "$un" "Created=$uc"
    fi
  done < <(aws_safe iam list-users --query "Users[].[UserName,CreateDate]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  start_table "IAM Groups"
  while read -r gn; do
    [[ -z "$gn" ]] && continue
    if ! is_managed "$gn"; then
      record "IAM Group" "global" "$gn" ""
    fi
  done < <(aws_safe iam list-groups --query "Groups[].GroupName" --output json | jq -r '.[]?')

  start_table "IAM Policies (customer-managed)"
  while IFS='|' read -r pn parn pc; do
    [[ -z "$pn" ]] && continue
    if ! is_managed "$pn" "$parn"; then
      record "IAM Policy" "global" "$pn" "ARN=$parn Created=$pc"
    fi
  done < <(aws_safe iam list-policies --scope Local \
    --query "Policies[].[PolicyName,Arn,CreateDate]" --output json | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')

  start_table "CloudTrail Trails"
  while IFS='|' read -r tn tb tm; do
    [[ -z "$tn" ]] && continue
    if ! is_managed "$tn"; then
      record "CloudTrail" "global" "$tn" "Bucket=$tb MultiRegion=$tm"
    fi
  done < <(aws_safe cloudtrail describe-trails --include-shadow-trails \
    --query "trailList[].[Name,S3BucketName,IsMultiRegionTrail]" --output json \
    | jq -r '.[] | map(if . == null then "" else tostring end) | join("|")')
}

# -----------------------------------------------------------------------------
# Run scans
# -----------------------------------------------------------------------------
scan_global
for R in "${REGIONS[@]}"; do
  scan_region "$R"
done

# -----------------------------------------------------------------------------
## Finalise reports
FINDINGS_JSON+="]"

{
  echo ""
  echo "---"
  echo ""
  echo "## Summary"
  echo ""
  echo "- **Total unmanaged resources:** $COUNT"
  echo "- **Managed identifiers checked:** $MANAGED_COUNT"
  echo "- **Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
} >> "$REPORT_MD"

jq -n \
  --arg account "$ACCOUNT_ID" \
  --arg caller "$CALLER_ARN" \
  --arg tf_dir "$TF_DIR" \
  --argjson regions "$(printf '%s\n' "${REGIONS[@]}" | jq -R . | jq -s .)" \
  --argjson managed "$RES_COUNT" \
  --argjson findings "$FINDINGS_JSON" \
  '{
     account:$account, caller:$caller, terraform_dir:$tf_dir,
     regions:$regions, managed_resources:$managed,
     unmanaged_count: ($findings | length),
     findings: $findings,
     generated_at: (now | todate)
   }' > "$REPORT_JSON"

section "Scan complete"
info "Markdown report: $REPORT_MD"
info "JSON report:     $REPORT_JSON"
info "Total unmanaged resources: $COUNT"

if $OUT_JSON; then cat "$REPORT_JSON"; fi

# -----------------------------------------------------------------------------
# Slack integration: send report to Slack if configured.

# The webhook URL is taken from (in order of preference):
#   1. $SLACK_WEBHOOK_URL environment variable (highest priority).
#   2. `slack_webhook_url = "..."` in the discovered Terraform stack's
#      terraform.tfvars (i.e. $TF_DIR/terraform.tfvars).
#   3. ./terraform.tfvars and ./aws/terraform.tfvars (legacy fallbacks).
# -----------------------------------------------------------------------------

# Allow the integration to be disabled entirely via env var.
SLACK_ENABLED="${SLACK_ENABLED:-1}"

if [[ "$SLACK_ENABLED" != "1" && "$SLACK_ENABLED" != "true" ]]; then
  info "Slack notifications disabled via SLACK_ENABLED=$SLACK_ENABLED."
else
  # Resolve the webhook URL. Only look inside the discovered TF_DIR - do
  # NOT fall back to ./terraform.tfvars or ./aws/terraform.tfvars from the
  # current working directory, because that's how reports end up being
  # posted to the wrong team's Slack channel when this module is run from
  # a different repo than the one it was originally designed for.
  if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
    TFVARS_FILE="$TF_DIR/terraform.tfvars"
    if [[ -f "$TFVARS_FILE" ]]; then
      SLACK_WEBHOOK_URL=$(awk -F' *= *' '/^slack_webhook_url *=/ {gsub(/\"/, "", $2); print $2}' "$TFVARS_FILE" | tr -d '"')
      [[ -n "$SLACK_WEBHOOK_URL" ]] && info "Slack webhook loaded from $TFVARS_FILE"
    fi
  else
    info "Slack webhook taken from SLACK_WEBHOOK_URL env var."
  fi

  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    AWS_ACCOUNT="$ACCOUNT_ID"
    REPORT="$REPORT_JSON"
    MESSAGE="*Unmanaged AWS Resources Report*\n*Repo:* $REPO_NAME\n*Account:* $AWS_ACCOUNT\n"
    RESOURCES=$(jq -r --arg acct "$AWS_ACCOUNT" '
      .findings[] |
      . as $f |
      # Robustly extract Name and Description (allow spaces and special chars until next key or end)
      (if ($f.detail | test("Name=")) then ($f.detail | match("Name=([^ ]+.*?)( |$|State=|Size=|Type=|Region=|AllocationId=|Assoc=|$)") | .captures[0].string // null) else null end) as $name |
      (if ($f.detail | test("Description=")) then ($f.detail | match("Description=([^ ]+.*?)( |$|State=|Size=|Type=|Region=|AllocationId=|Assoc=|$)") | .captures[0].string // null) else null end) as $desc |
      # Build AWS Console link for known types
      (if $f.category == "S3 Bucket" then
         "https://s3.console.aws.amazon.com/s3/buckets/" + $f.id + "?region=" + ($f.detail | capture("Region=(?<r>[^ ]+)") | .r // $f.region)
       elif $f.category == "EBS Volume" then
         "https://console.aws.amazon.com/ec2/v2/home?region=" + $f.region + "#Volumes:search=" + $f.id
       elif $f.category == "Elastic IP" then
         "https://console.aws.amazon.com/ec2/v2/home?region=" + $f.region + "#Addresses:PublicIp=" + $f.id
       else null end) as $link |
      # Format block: always prefer Name, then Description, then ID as heading
      ("*● " +
        (if ($name | length) > 0 then $name
         elif ($desc | length) > 0 then $desc
         else $f.id end) +
        "*\n" +
        "ID: " + (if $link then "<" + $link + "|" + $f.id + ">" else $f.id end) + "\n" +
        "Category: " + $f.category + "\n" +
        "Detail: " + $f.detail + "\n" +
        "Region: " + $f.region + "\n---\n"
      )
    ' "$REPORT")
    if [[ -z "$RESOURCES" ]]; then
      MESSAGE+="No unmanaged resources found :tada:"
    else
      MESSAGE+="$RESOURCES"
    fi
    payload=$(jq -Rs --arg text "$MESSAGE" '{text: $text}' <<< "")
    curl -sS -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL" >/dev/null \
      && info "Sent report to Slack." \
      || warn "Slack POST failed (curl exit $?)."
  else
    warn "No Slack webhook found (set SLACK_WEBHOOK_URL or slack_webhook_url in $TF_DIR/terraform.tfvars); skipping Slack notification."
  fi
fi
