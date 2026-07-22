from .common import paginator, safe


@safe
def log_groups(session, region):
    logs=session.client("logs", region_name=region); out=[]
    for lg in paginator(logs,"describe_log_groups","logGroups"):
        name=lg["logGroupName"]
        if name.startswith("/aws/"):
            continue
        out.append({"type":"Log Group","id":name,"arn":lg.get("arn"),"name":name,"region":region,"tags":{},"raw":{"retention":lg.get("retentionInDays")}})
    return out


@safe
def ssm_parameters(session, region):
    ssm=session.client("ssm", region_name=region); out=[]
    for p in paginator(ssm,"describe_parameters","Parameters"):
        name=p["Name"]
        if name.startswith("/aws/"):
            continue
        out.append({"type":"SSM Param","id":name,"name":name,"region":region,"tags":{},"raw":{"type":p.get("Type"),"last_modified":str(p.get("LastModifiedDate", ""))}})
    return out


@safe
def schedules(session, region):
    scheduler=session.client("scheduler", region_name=region); out=[]
    for s in paginator(scheduler,"list_schedules","Schedules"):
        out.append({"type":"Schedule","id":s["Name"],"arn":s.get("Arn"),"name":s["Name"],"region":region,"tags":{},"raw":{"group":s.get("GroupName"),"state":s.get("State")}})
    return out


@safe
def secrets(session, region):
    sm=session.client("secretsmanager", region_name=region); out=[]
    for s in paginator(sm,"list_secrets","SecretList"):
        out.append({"type":"Secret","id":s["Name"],"arn":s.get("ARN"),"name":s["Name"],"region":region,"tags":{},"raw":{"last_changed":str(s.get("LastChangedDate", ""))}})
    return out
