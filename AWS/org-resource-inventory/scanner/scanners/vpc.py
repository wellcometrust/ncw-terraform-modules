from .common import arn, name_from_tags, paginator, safe, tags


def _acct(session):
    return session.client("sts").get_caller_identity()["Account"]


def _default_vpc(ec2):
    vpcs = ec2.describe_vpcs(Filters=[{"Name":"is-default","Values":["true"]}]).get("Vpcs", [])
    return vpcs[0]["VpcId"] if vpcs else None


@safe
def vpcs(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for v in paginator(ec2,"describe_vpcs","Vpcs"):
        if v.get("IsDefault"):
            continue
        t=tags(v.get("Tags")); vid=v["VpcId"]
        out.append({"type":"VPC","id":vid,"arn":arn("ec2",region,account,f"vpc/{vid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"cidr":v.get("CidrBlock")}})
    return out


@safe
def security_groups(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session); default=_default_vpc(ec2)
    for sg in paginator(ec2,"describe_security_groups","SecurityGroups"):
        if sg.get("GroupName") == "default" or (default and sg.get("VpcId") == default):
            continue
        gid=sg["GroupId"]
        out.append({"type":"Security Group","id":gid,"arn":arn("ec2",region,account,f"security-group/{gid}"),"name":sg.get("GroupName"),"region":region,"tags":tags(sg.get("Tags")),"raw":{"vpc_id":sg.get("VpcId"),"description":sg.get("Description")}})
    return out


@safe
def subnets(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session); default=_default_vpc(ec2)
    for s in paginator(ec2,"describe_subnets","Subnets"):
        if default and s.get("VpcId") == default:
            continue
        t=tags(s.get("Tags")); sid=s["SubnetId"]
        out.append({"type":"Subnet","id":sid,"arn":arn("ec2",region,account,f"subnet/{sid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"cidr":s.get("CidrBlock"),"vpc_id":s.get("VpcId")}})
    return out


@safe
def route_tables(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session); default=_default_vpc(ec2)
    for rt in paginator(ec2,"describe_route_tables","RouteTables"):
        if default and rt.get("VpcId") == default:
            continue
        if any(a.get("Main") for a in rt.get("Associations", [])):
            continue
        t=tags(rt.get("Tags")); rid=rt["RouteTableId"]
        out.append({"type":"Route Table","id":rid,"arn":arn("ec2",region,account,f"route-table/{rid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"vpc_id":rt.get("VpcId")}})
    return out


@safe
def internet_gateways(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session); default=_default_vpc(ec2)
    for igw in paginator(ec2,"describe_internet_gateways","InternetGateways"):
        vpc=(igw.get("Attachments") or [{}])[0].get("VpcId")
        if default and vpc == default:
            continue
        t=tags(igw.get("Tags")); iid=igw["InternetGatewayId"]
        out.append({"type":"Internet Gateway","id":iid,"arn":arn("ec2",region,account,f"internet-gateway/{iid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"vpc_id":vpc}})
    return out


@safe
def network_acls(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session); default=_default_vpc(ec2)
    for nacl in paginator(ec2,"describe_network_acls","NetworkAcls"):
        if nacl.get("IsDefault") or (default and nacl.get("VpcId") == default):
            continue
        t=tags(nacl.get("Tags")); nid=nacl["NetworkAclId"]
        out.append({"type":"Network ACL","id":nid,"arn":arn("ec2",region,account,f"network-acl/{nid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"vpc_id":nacl.get("VpcId")}})
    return out


@safe
def vpc_endpoints(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for ep in paginator(ec2,"describe_vpc_endpoints","VpcEndpoints"):
        if ep.get("State") == "deleted":
            continue
        t=tags(ep.get("Tags")); eid=ep["VpcEndpointId"]
        out.append({"type":"VPC Endpoint","id":eid,"arn":arn("ec2",region,account,f"vpc-endpoint/{eid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"service":ep.get("ServiceName"),"vpc_id":ep.get("VpcId")}})
    return out


@safe
def enis(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for eni in paginator(ec2,"describe_network_interfaces","NetworkInterfaces"):
        t=tags(eni.get("TagSet")); eid=eni["NetworkInterfaceId"]
        out.append({"type":"ENI","id":eid,"arn":arn("ec2",region,account,f"network-interface/{eid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"status":eni.get("Status"),"vpc_id":eni.get("VpcId"),"description":eni.get("Description")}})
    return out


@safe
def nat_gateways(session, region):
    out=[]; ec2=session.client("ec2", region_name=region); account=_acct(session)
    for nat in paginator(ec2,"describe_nat_gateways","NatGateways"):
        if nat.get("State") == "deleted":
            continue
        t=tags(nat.get("Tags")); nid=nat["NatGatewayId"]
        out.append({"type":"NAT Gateway","id":nid,"arn":arn("ec2",region,account,f"natgateway/{nid}"),"name":name_from_tags(t),"region":region,"tags":t,"raw":{"state":nat.get("State"),"vpc_id":nat.get("VpcId")}})
    return out
