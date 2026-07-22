from .common import paginator, safe


@safe
def roles(session, region):
    iam=session.client("iam"); out=[]
    for r in paginator(iam,"list_roles","Roles"):
        name=r["RoleName"]; path=r.get("Path", "")
        if name.startswith(("AWS", "aws-", "AWSReserved")) or path.startswith("/aws-service-role/"):
            continue
        out.append({"type":"IAM Role","id":name,"arn":r.get("Arn"),"name":name,"region":"global","tags":{},"raw":{"created":str(r.get("CreateDate", "")),"path":path}})
    return out


@safe
def users(session, region):
    iam=session.client("iam")
    return [{"type":"IAM User","id":u["UserName"],"arn":u.get("Arn"),"name":u["UserName"],"region":"global","tags":{},"raw":{"created":str(u.get("CreateDate", ""))}} for u in paginator(iam,"list_users","Users")]


@safe
def groups(session, region):
    iam=session.client("iam")
    return [{"type":"IAM Group","id":g["GroupName"],"arn":g.get("Arn"),"name":g["GroupName"],"region":"global","tags":{},"raw":{"created":str(g.get("CreateDate", ""))}} for g in paginator(iam,"list_groups","Groups")]


@safe
def policies(session, region):
    iam=session.client("iam")
    return [{"type":"IAM Policy","id":p["PolicyName"],"arn":p.get("Arn"),"name":p["PolicyName"],"region":"global","tags":{},"raw":{"created":str(p.get("CreateDate", ""))}} for p in paginator(iam,"list_policies","Policies",Scope="Local")]


@safe
def cloudtrails(session, region):
    ct=session.client("cloudtrail", region_name="us-east-1")
    trails=ct.describe_trails(includeShadowTrails=True).get("trailList", [])
    return [{"type":"CloudTrail","id":t["Name"],"arn":t.get("TrailARN"),"name":t["Name"],"region":"global","tags":{},"raw":{"bucket":t.get("S3BucketName"),"multi_region":t.get("IsMultiRegionTrail")}} for t in trails]
