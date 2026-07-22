from .common import arn, name_from_tags, paginator, safe, tags


def _acct(session):
    return session.client("sts").get_caller_identity()["Account"]


@safe
def instances(session, region):
    out = []
    ec2 = session.client("ec2", region_name=region)
    account = _acct(session)
    for page in ec2.get_paginator("describe_instances").paginate():
        for res in page.get("Reservations", []):
            for i in res.get("Instances", []):
                if i.get("State", {}).get("Name") == "terminated":
                    continue
                t = tags(i.get("Tags"))
                iid = i["InstanceId"]
                out.append({"type":"EC2 Instance","id":iid,"arn":arn("ec2", region, account, f"instance/{iid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"state":i.get("State",{}).get("Name"),"instance_type":i.get("InstanceType")}})
    return out


@safe
def volumes(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for v in paginator(ec2,"describe_volumes","Volumes",Filters=[{"Name":"status","Values":["in-use","available"]}]):
        t=tags(v.get("Tags")); name=name_from_tags(t)
        if not name:
            continue
        vid=v["VolumeId"]
        out.append({"type":"EBS Volume","id":vid,"arn":arn("ec2",region,account,f"volume/{vid}"),"name":name,"region":region,"tags":t,"raw":{"state":v.get("State"),"size":v.get("Size"),"volume_type":v.get("VolumeType")}})
    return out


@safe
def snapshots(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for s in paginator(ec2,"describe_snapshots","Snapshots",OwnerIds=["self"]):
        t=tags(s.get("Tags")); sid=s["SnapshotId"]
        out.append({"type":"EBS Snapshot","id":sid,"arn":arn("ec2",region,account,f"snapshot/{sid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"state":s.get("State"),"volume_id":s.get("VolumeId"),"description":s.get("Description")}})
    return out


@safe
def amis(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for img in paginator(ec2,"describe_images","Images",Owners=["self"]):
        t=tags(img.get("Tags")); image_id=img["ImageId"]
        out.append({"type":"AMI","id":image_id,"arn":arn("ec2",region,account,f"image/{image_id}"),"name":img.get("Name") or name_from_tags(t),"region":region,"tags":t,"raw":{"state":img.get("State"),"creation_date":img.get("CreationDate")}})
    return out


@safe
def elastic_ips(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for a in paginator(ec2,"describe_addresses","Addresses"):
        t=tags(a.get("Tags")); alloc=a.get("AllocationId") or a.get("PublicIp")
        out.append({"type":"Elastic IP","id":a.get("PublicIp") or alloc,"arn":arn("ec2",region,account,f"elastic-ip/{alloc}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"allocation_id":alloc,"association_id":a.get("AssociationId")}})
    return out


@safe
def key_pairs(session, region):
    ec2=session.client("ec2", region_name=region)
    return [{"type":"Key Pair","id":k["KeyName"],"name":k.get("KeyName"),"region":region,"tags":{},"raw":{"key_type":k.get("KeyType"),"created":str(k.get("CreateTime", ""))}} for k in paginator(ec2,"describe_key_pairs","KeyPairs")]
