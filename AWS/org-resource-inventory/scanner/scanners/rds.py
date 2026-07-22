from .common import safe


@safe
def instances(session, region):
    rds=session.client("rds", region_name=region); out=[]
    for page in rds.get_paginator("describe_db_instances").paginate():
        for db in page.get("DBInstances", []):
            ident=db["DBInstanceIdentifier"]
            out.append({"type":"RDS","id":ident,"arn":db.get("DBInstanceArn"),"name":ident,"region":region,"tags":{},"raw":{"class":db.get("DBInstanceClass"),"engine":db.get("Engine"),"status":db.get("DBInstanceStatus")}})
    return out


@safe
def snapshots(session, region):
    rds=session.client("rds", region_name=region); out=[]
    for page in rds.get_paginator("describe_db_snapshots").paginate(SnapshotType="manual"):
        for snap in page.get("DBSnapshots", []):
            sid=snap["DBSnapshotIdentifier"]
            out.append({"type":"RDS Snapshot","id":sid,"arn":snap.get("DBSnapshotArn"),"name":sid,"region":region,"tags":{},"raw":{"status":snap.get("Status"),"instance":snap.get("DBInstanceIdentifier")}})
    return out
