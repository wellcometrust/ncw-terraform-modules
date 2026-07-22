from .common import paginator, safe


@safe
def keys(session, region):
    kms=session.client("kms", region_name=region); out=[]
    for a in paginator(kms,"list_aliases","Aliases"):
        name=a.get("AliasName", "")
        if not name.startswith("alias/") or name.startswith("alias/aws/") or not a.get("TargetKeyId"):
            continue
        out.append({"type":"KMS Key","id":name,"arn":None,"name":name,"region":region,"tags":{},"raw":{"key_id":a.get("TargetKeyId")}})
    return out
