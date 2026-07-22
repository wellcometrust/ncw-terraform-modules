from .common import safe


@safe
def buckets(session, region):
    s3=session.client("s3"); out=[]
    for b in s3.list_buckets().get("Buckets", []):
        name=b["Name"]
        try:
            loc=s3.get_bucket_location(Bucket=name).get("LocationConstraint") or "us-east-1"
        except Exception:
            loc="unknown"
        out.append({"type":"S3 Bucket","id":name,"arn":f"arn:aws:s3:::{name}","name":name,"region":"global","tags":{},"raw":{"bucket_region":loc,"created":str(b.get("CreationDate", ""))}})
    return out
