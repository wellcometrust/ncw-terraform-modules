output "cloudfront_domain" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.inventory.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.inventory.id
}

output "reports_bucket" {
  description = "S3 bucket containing scanner JSON reports."
  value       = aws_s3_bucket.reports.id
}

output "frontend_bucket" {
  description = "S3 bucket containing frontend assets."
  value       = aws_s3_bucket.frontend.id
}

output "scanner_lambda_arn" {
  description = "Scanner Lambda ARN."
  value       = aws_lambda_function.scanner.arn
}

output "scanner_lambda_name" {
  description = "Scanner Lambda function name."
  value       = aws_lambda_function.scanner.function_name
}

output "waf_ipset_arn" {
  description = "WAFv2 IP set ARN."
  value       = aws_wafv2_ip_set.allowed.arn
}

output "scanner_function_url" {
  description = "Direct Function URL for the scanner Lambda (also fronted by CloudFront at /api/scan)."
  value       = aws_lambda_function_url.scanner.function_url
}
