import json
from datetime import datetime, timezone


def write_report(session, bucket, report):
    s3 = session.client("s3")
    body = json.dumps(report, default=str, separators=(",", ":")).encode("utf-8")
    now = datetime.now(timezone.utc)
    history_key = f"history/{now:%Y-%m-%d}/{now:%H%M%S}.json"
    for key, cache in [("latest.json", "no-cache"), (history_key, None)]:
        kwargs = {"Bucket": bucket, "Key": key, "Body": body, "ContentType": "application/json"}
        if cache:
            kwargs["CacheControl"] = cache
        s3.put_object(**kwargs)
    return {"latest": "latest.json", "history": history_key}
