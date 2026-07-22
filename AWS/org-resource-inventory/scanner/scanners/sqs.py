from .common import safe


@safe
def queues(session, region):
    sqs=session.client("sqs", region_name=region); urls=sqs.list_queues().get("QueueUrls", []); out=[]
    for url in urls:
        name=url.split('/')[-1]
        out.append({"type":"SQS Queue","id":name,"name":name,"region":region,"tags":{},"raw":{"url":url}})
    return out
