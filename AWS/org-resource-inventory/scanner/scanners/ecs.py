from .common import safe


@safe
def clusters(session, region):
    ecs=session.client("ecs", region_name=region); arns=[]; out=[]
    for page in ecs.get_paginator("list_clusters").paginate():
        arns.extend(page.get("clusterArns", []))
    for arn in arns:
        out.append({"type":"ECS Cluster","id":arn.split('/')[-1],"arn":arn,"name":arn.split('/')[-1],"region":region,"tags":{},"raw":{}})
    return out


@safe
def services(session, region):
    ecs=session.client("ecs", region_name=region); out=[]
    for page in ecs.get_paginator("list_clusters").paginate():
        for cluster in page.get("clusterArns", []):
            for svc_page in ecs.get_paginator("list_services").paginate(cluster=cluster):
                for arn in svc_page.get("serviceArns", []):
                    name=arn.split('/')[-1]
                    out.append({"type":"ECS Service","id":name,"arn":arn,"name":name,"region":region,"tags":{},"raw":{"cluster":cluster.split('/')[-1]}})
    return out


@safe
def ecr_repositories(session, region):
    ecr=session.client("ecr", region_name=region); out=[]
    for page in ecr.get_paginator("describe_repositories").paginate():
        for repo in page.get("repositories", []):
            out.append({"type":"ECR Repo","id":repo["repositoryName"],"arn":repo.get("repositoryArn"),"name":repo["repositoryName"],"region":region,"tags":{},"raw":{"uri":repo.get("repositoryUri")}})
    return out
