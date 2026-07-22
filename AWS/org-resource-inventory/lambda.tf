locals {
  scanner_files = fileset("${path.module}/scanner", "**/*")
  scanner_hash  = sha256(join("", [for file in local.scanner_files : filesha256("${path.module}/scanner/${file}")]))
}

resource "null_resource" "scanner_package" {
  triggers = {
    scanner_hash      = local.scanner_hash
    requirements_hash = filesha256("${path.module}/scanner/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      cd "${path.module}"
      rm -rf build/scanner_deps build/package
      mkdir -p build/scanner_deps build/package
      pip install -r scanner/requirements.txt -t build/scanner_deps --quiet
      cp -R build/scanner_deps/. build/package/
      cp -R scanner/. build/package/
    EOT
  }
}

data "archive_file" "scanner" {
  type        = "zip"
  source_dir  = "${path.module}/build/package"
  output_path = "${path.module}/build/scanner.zip"

  depends_on = [null_resource.scanner_package]
}

resource "aws_cloudwatch_log_group" "scanner" {
  name              = "/aws/lambda/${var.name_prefix}-scanner"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "scanner" {
  function_name    = "${var.name_prefix}-scanner"
  role             = aws_iam_role.scanner.arn
  filename         = data.archive_file.scanner.output_path
  source_code_hash = data.archive_file.scanner.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb
  tags             = local.common_tags

  environment {
    variables = {
      REPORTS_BUCKET        = aws_s3_bucket.reports.id
      MEMBER_ROLE_NAME      = var.member_role_name
      REGIONS               = jsonencode(var.regions)
      INCLUDED_ACCOUNTS     = jsonencode(var.included_account_ids)
      EXCLUDED_ACCOUNTS     = jsonencode(var.excluded_account_ids)
      TF_STATE_BUCKETS      = jsonencode(var.tf_state_bucket_names)
      RESOURCE_TYPES        = jsonencode(var.resource_types)
      EXTRA_IGNORE_PATTERNS = jsonencode(var.extra_ignore_patterns)
    }
  }

  depends_on = [aws_cloudwatch_log_group.scanner]
}

resource "aws_cloudwatch_event_rule" "scanner" {
  name                = "${var.name_prefix}-scanner"
  description         = "Run org resource inventory scanner"
  schedule_expression = var.schedule_expression
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "scanner" {
  rule      = aws_cloudwatch_event_rule.scanner.name
  target_id = "scanner"
  arn       = aws_lambda_function.scanner.arn
}

resource "aws_lambda_function_url" "scanner" {
  function_name      = aws_lambda_function.scanner.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_lambda_permission" "function_url" {
  statement_id           = "AllowFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.scanner.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scanner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scanner.arn
}
