import json
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

import boto3

from org import assume, list_accounts, org_id
from scanners import REGISTRY
from tfstate import load as load_state
from writer import write_report

DEFAULT_IGNORE = [
    "tfstate", "terraform-state", "terraform-states", "Key Pair", "org-level", "stacksets",
    "QuickSetup", "quicksetup", "Softcat", "softcat",
]


def _json_env(name, default):
    raw = os.environ.get(name)
    return json.loads(raw) if raw else default


def _matches(value, candidates):
    return any(candidate and candidate in value for candidate in candidates)


def _ignored(resource, patterns):
    haystack = " ".join(str(x or "") for x in [
        resource.get("type"), resource.get("id"), resource.get("arn"), resource.get("name"), resource.get("raw"), resource.get("tags"),
    ]).lower()
    return any(p.lower() in haystack for p in patterns if p)


def _mark(resource, managed_ids, cfn_ids, ignore_patterns):
    candidates = {str(v) for v in [resource.get("id"), resource.get("arn"), resource.get("name")] if v}
    candidates.update(str(v) for v in (resource.get("tags") or {}).values() if v)
    if _ignored(resource, ignore_patterns):
        status = "ignored"
    elif any(c in managed_ids for c in candidates):
        status = "managed"
    elif any(c in cfn_ids for c in candidates):
        status = "cloudformation"
    else:
        status = "unmanaged"
    resource["management_status"] = status
    return resource


def _scan_region(session, region, scanners):
    resources = []
    for _, scanner in scanners:
        resources.extend(scanner(session, region))
    return resources


def _scan_account(account, cfg, lambda_session):
    errors = []
    resources = []
    try:
        session = assume(account["id"], cfg["member_role_name"])
        managed, cfn = load_state(account["id"], session, lambda_session, cfg["state_buckets"], cfg["regions"])
        selected = [(name, fn) for name, fn in REGISTRY.items() if not cfg["types"] or name in cfg["types"]]
        global_scanners = [(n, f) for n, f in selected if getattr(f, "global_only", False)]
        regional_scanners = [(n, f) for n, f in selected if not getattr(f, "global_only", False)]
        for _, scanner in global_scanners:
            resources.extend(scanner(session, "global"))
        with ThreadPoolExecutor(max_workers=4) as region_pool:
            futs = {region_pool.submit(_scan_region, session, r, regional_scanners): r for r in cfg["regions"]}
            for fut in as_completed(futs):
                try:
                    resources.extend(fut.result())
                except Exception as exc:
                    errors.append({"region": futs[fut], "error": str(exc)})
        resources = [_mark(r, managed, cfn, cfg["ignore_patterns"]) for r in resources]
    except Exception as exc:
        errors.append({"region": "account", "error": str(exc)})
    counts = {"total": len(resources), "managed": 0, "unmanaged": 0, "ignored": 0, "cloudformation": 0}
    for resource in resources:
        counts[resource["management_status"]] = counts.get(resource["management_status"], 0) + 1
    return {**account, "resources": resources, "counts": counts, "errors": errors}


def _http_response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", "Cache-Control": "no-store"},
        "body": json.dumps(body),
    }


def _handle_http(event, context):
    method = (event.get("requestContext", {}).get("http", {}) or {}).get("method", "GET")
    if method == "OPTIONS":
        return _http_response(204, {})
    if method != "POST":
        return _http_response(405, {"error": "method not allowed"})
    client = boto3.client("lambda")
    client.invoke(
        FunctionName=context.function_name,
        InvocationType="Event",
        Payload=json.dumps({"source": "on-demand"}).encode("utf-8"),
    )
    return _http_response(202, {"ok": True, "message": "scan started"})


def handler(event, context):
    if isinstance(event, dict) and event.get("requestContext", {}).get("http"):
        return _handle_http(event, context)
    cfg = {
        "bucket": os.environ["REPORTS_BUCKET"],
        "member_role_name": os.environ.get("MEMBER_ROLE_NAME", "OrganizationAccountAccessRole"),
        "regions": _json_env("REGIONS", []),
        "included": _json_env("INCLUDED_ACCOUNTS", []),
        "excluded": _json_env("EXCLUDED_ACCOUNTS", []),
        "state_buckets": _json_env("TF_STATE_BUCKETS", {}),
        "types": set(_json_env("RESOURCE_TYPES", [])),
        "ignore_patterns": DEFAULT_IGNORE + _json_env("EXTRA_IGNORE_PATTERNS", []),
    }
    lambda_session = boto3.Session()
    accounts = list_accounts(cfg["included"], cfg["excluded"])
    scanned = []
    with ThreadPoolExecutor(max_workers=10) as pool:
        futs = [pool.submit(_scan_account, account, cfg, lambda_session) for account in accounts]
        for fut in as_completed(futs):
            scanned.append(fut.result())
    summary = {"total": 0, "managed": 0, "unmanaged": 0, "ignored": 0, "cloudformation": 0}
    for account in scanned:
        for key in summary:
            summary[key] += account["counts"].get(key, 0)
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "org_id": org_id(),
        "accounts": sorted(scanned, key=lambda a: a["id"]),
        "summary": summary,
    }
    keys = write_report(lambda_session, cfg["bucket"], report)
    return {"ok": True, "accounts": len(scanned), "summary": summary, "keys": keys}
