resource "aws_wafv2_ip_set" "allowed" {
  provider           = aws.us_east_1
  name               = "${var.name_prefix}-allowed-cidrs"
  description        = "CIDRs allowed to access org inventory"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allowed_cidrs
  tags               = local.common_tags
}

resource "aws_wafv2_web_acl" "inventory" {
  provider    = aws.us_east_1
  name        = "${var.name_prefix}-inventory"
  description = "IP allow-list for org inventory CloudFront distribution"
  scope       = "CLOUDFRONT"
  tags        = local.common_tags

  default_action {
    block {}
  }

  rule {
    name     = "allow-listed-cidrs"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-allowed-cidrs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-inventory"
    sampled_requests_enabled   = true
  }
}
