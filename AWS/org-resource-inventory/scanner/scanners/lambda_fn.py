from .common import paginator, safe


@safe
def functions(session, region):
    client=session.client("lambda", region_name=region); out=[]
    for f in paginator(client,"list_functions","Functions"):
        out.append({"type":"Lambda","id":f["FunctionName"],"arn":f.get("FunctionArn"),"name":f["FunctionName"],"region":region,"tags":{},"raw":{"runtime":f.get("Runtime"),"last_modified":f.get("LastModified")}})
    return out
