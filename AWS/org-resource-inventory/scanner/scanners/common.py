from botocore.exceptions import ClientError

DENIED = {"AccessDenied", "AccessDeniedException", "UnauthorizedOperation", "AuthFailure", "UnrecognizedClientException"}


def denied(exc):
    return isinstance(exc, ClientError) and exc.response.get("Error", {}).get("Code") in DENIED


def tags(items):
    if not items:
        return {}
    return {t.get("Key", ""): t.get("Value", "") for t in items if t.get("Key")}


def name_from_tags(tag_dict):
    return tag_dict.get("Name", "")


def arn(service, region, account_id, resource):
    region_part = region or ""
    return f"arn:aws:{service}:{region_part}:{account_id}:{resource}"


def paginator(client, op, result_key, **kwargs):
    for page in client.get_paginator(op).paginate(**kwargs):
        for item in page.get(result_key, []):
            yield item


def safe(fn):
    def wrapped(session, region):
        try:
            return fn(session, region)
        except Exception as exc:
            if denied(exc):
                return []
            raise
    return wrapped
