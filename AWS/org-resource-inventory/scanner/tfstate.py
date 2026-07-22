import json

import boto3
from botocore.exceptions import ClientError

STACK_STATUSES = [
    "CREATE_COMPLETE", "UPDATE_COMPLETE", "UPDATE_ROLLBACK_COMPLETE", "IMPORT_COMPLETE",
]


def _walk_resources(module):
    for res in module.get("resources", []):
        yield res.get("values", {})
    for child in module.get("child_modules", []):
        yield from _walk_resources(child)


def _add_value(out, value):
    if value not in (None, ""):
        out.add(str(value))


def _extract_state_ids(body):
    data = json.loads(body)
    root = data.get("values", {}).get("root_module", {})
    ids = set()
    keys = [
        "id", "arn", "name", "bucket", "key_name", "function_name", "role_name", "user_name",
        "group_name", "policy_name", "alias", "alias_name", "log_group_name", "parameter_name",
        "schedule_name", "detector_id", "repository_name", "cluster_name", "topic_arn", "queue_url",
        "vpc_id", "subnet_id", "security_group_id", "internet_gateway_id", "route_table_id",
        "network_acl_id", "volume_id", "image_id", "snapshot_id", "public_ip", "allocation_id",
        "load_balancer_arn", "target_group_arn", "db_instance_identifier", "table_name",
    ]
    for values in _walk_resources(root):
        for key in keys:
            _add_value(ids, values.get(key))
        tags = values.get("tags") or {}
        if isinstance(tags, dict):
            _add_value(ids, tags.get("Name"))
    return ids


def _list_tfstates(s3, bucket):
    keys = []
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket):
        for obj in page.get("Contents", []):
            key = obj.get("Key", "")
            if key.endswith(".tfstate"):
                keys.append(key)
    return keys


def _cfn_ids(session, regions):
    ids = set()
    for region in regions:
        client = session.client("cloudformation", region_name=region)
        try:
            pages = client.get_paginator("list_stacks").paginate(StackStatusFilter=STACK_STATUSES)
            for page in pages:
                for stack in page.get("StackSummaries", []):
                    name = stack.get("StackName")
                    for res_page in client.get_paginator("list_stack_resources").paginate(StackName=name):
                        for res in res_page.get("StackResourceSummaries", []):
                            _add_value(ids, res.get("PhysicalResourceId"))
        except ClientError as exc:
            if exc.response.get("Error", {}).get("Code") in {"AccessDenied", "AccessDeniedException", "UnauthorizedOperation"}:
                continue
            raise
    return ids


def load(account_id, member_session, lambda_session, state_buckets, regions):
    managed = set()
    bucket = state_buckets.get(account_id)
    if bucket:
        s3 = lambda_session.client("s3")
        for key in _list_tfstates(s3, bucket):
            obj = s3.get_object(Bucket=bucket, Key=key)
            managed.update(_extract_state_ids(obj["Body"].read().decode("utf-8")))
    return managed, _cfn_ids(member_session, regions)
