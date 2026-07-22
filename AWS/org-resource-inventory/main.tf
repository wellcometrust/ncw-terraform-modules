data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix          = var.name_prefix
  reports_bucket_name  = "${var.name_prefix}-reports-${data.aws_caller_identity.current.account_id}"
  frontend_bucket_name = "${var.name_prefix}-frontend-${data.aws_caller_identity.current.account_id}"

  common_tags = merge(var.tags, {
    Module = "org-resource-inventory"
  })

  frontend_content_types = {
    css   = "text/css"
    html  = "text/html"
    ico   = "image/x-icon"
    js    = "application/javascript"
    json  = "application/json"
    map   = "application/json"
    png   = "image/png"
    svg   = "image/svg+xml"
    txt   = "text/plain"
    webp  = "image/webp"
    woff  = "font/woff"
    woff2 = "font/woff2"
  }
}
