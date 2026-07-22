from .common import safe


@safe
def tables(session, region):
    ddb=session.client("dynamodb", region_name=region); out=[]
    for page in ddb.get_paginator("list_tables").paginate():
        for name in page.get("TableNames", []):
            desc=ddb.describe_table(TableName=name)["Table"]
            out.append({"type":"DynamoDB Table","id":name,"arn":desc.get("TableArn"),"name":name,"region":region,"tags":{},"raw":{"status":desc.get("TableStatus"),"billing_mode":desc.get("BillingModeSummary",{}).get("BillingMode")}})
    return out
