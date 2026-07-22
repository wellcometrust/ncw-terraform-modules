locals {
  tf_state_bucket_arns = flatten([
    for bucket_name in values(var.tf_state_bucket_names) : [
      "arn:aws:s3:::${bucket_name}",
      "arn:aws:s3:::${bucket_name}/*",
    ]
  ])
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scanner" {
  name               = "${var.name_prefix}-scanner"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "scanner_basic" {
  role       = aws_iam_role.scanner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "scanner" {
  statement {
    sid = "OrganizationsRead"
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListAccounts",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AssumeMemberRoles"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/${var.member_role_name}"]
  }

  dynamic "statement" {
    for_each = length(local.tf_state_bucket_arns) > 0 ? [1] : []

    content {
      sid = "ReadTerraformState"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = local.tf_state_bucket_arns
    }
  }

  statement {
    sid       = "SelfInvokeForOnDemandScan"
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:*:*:function:${var.name_prefix}-scanner"]
  }

  statement {
    sid = "ReportsBucketAccess"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.reports.arn,
      "${aws_s3_bucket.reports.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "scanner" {
  name   = "${var.name_prefix}-scanner"
  role   = aws_iam_role.scanner.id
  policy = data.aws_iam_policy_document.scanner.json
}
