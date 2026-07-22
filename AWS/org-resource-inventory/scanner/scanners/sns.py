from .common import paginator, safe


@safe
def topics(session, region):
    sns=session.client("sns", region_name=region); out=[]
    for topic in paginator(sns,"list_topics","Topics"):
        arn=topic["TopicArn"]; name=arn.split(":")[-1]
        out.append({"type":"SNS Topic","id":name,"arn":arn,"name":name,"region":region,"tags":{},"raw":{}})
    return out
