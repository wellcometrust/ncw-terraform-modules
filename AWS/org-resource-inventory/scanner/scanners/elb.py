from .common import paginator, safe


@safe
def load_balancers(session, region):
    elb=session.client("elbv2", region_name=region); out=[]
    for lb in paginator(elb,"describe_load_balancers","LoadBalancers"):
        out.append({"type":"Load Balancer","id":lb["LoadBalancerName"],"arn":lb.get("LoadBalancerArn"),"name":lb["LoadBalancerName"],"region":region,"tags":{},"raw":{"type":lb.get("Type"),"state":lb.get("State",{}).get("Code")}})
    return out


@safe
def target_groups(session, region):
    elb=session.client("elbv2", region_name=region); out=[]
    for tg in paginator(elb,"describe_target_groups","TargetGroups"):
        out.append({"type":"Target Group","id":tg["TargetGroupName"],"arn":tg.get("TargetGroupArn"),"name":tg["TargetGroupName"],"region":region,"tags":{},"raw":{"protocol":tg.get("Protocol"),"port":tg.get("Port")}})
    return out


@safe
def classic_load_balancers(session, region):
    elb=session.client("elb", region_name=region); out=[]
    for page in elb.get_paginator("describe_load_balancers").paginate():
        for lb in page.get("LoadBalancerDescriptions", []):
            out.append({"type":"Classic LB","id":lb["LoadBalancerName"],"name":lb["LoadBalancerName"],"region":region,"tags":{},"raw":{"dns_name":lb.get("DNSName")}})
    return out
