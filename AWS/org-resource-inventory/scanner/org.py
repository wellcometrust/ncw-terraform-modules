import boto3


def list_accounts(included=None, excluded=None):
    included = set(included or [])
    excluded = set(excluded or [])
    client = boto3.client("organizations")
    accounts = []
    for page in client.get_paginator("list_accounts").paginate():
        for account in page.get("Accounts", []):
            account_id = account["Id"]
            if account.get("Status") != "ACTIVE":
                continue
            if included and account_id not in included:
                continue
            if account_id in excluded:
                continue
            accounts.append({
                "id": account_id,
                "name": account.get("Name", ""),
                "email": account.get("Email", ""),
            })
    return accounts


def org_id():
    try:
        return boto3.client("organizations").describe_organization()["Organization"].get("Id")
    except Exception:
        return None


def assume(account_id, role_name):
    sts = boto3.client("sts")
    creds = sts.assume_role(
        RoleArn=f"arn:aws:iam::{account_id}:role/{role_name}",
        RoleSessionName="org-resource-inventory",
    )["Credentials"]
    return boto3.Session(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )
