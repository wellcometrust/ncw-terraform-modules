from .common import safe


@safe
def hosted_zones(session, region):
    r53=session.client("route53"); out=[]
    for page in r53.get_paginator("list_hosted_zones").paginate():
        for z in page.get("HostedZones", []):
            zid=z["Id"].split("/")[-1]
            out.append({"type":"Route53 Hosted Zone","id":zid,"arn":f"arn:aws:route53:::hostedzone/{zid}","name":z.get("Name", "").rstrip('.'),"region":"global","tags":{},"raw":{"private":z.get("Config",{}).get("PrivateZone"),"record_count":z.get("ResourceRecordSetCount")}})
    return out
