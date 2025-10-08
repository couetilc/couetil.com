output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for website hosting"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "logs_bucket_name" {
  description = "S3 bucket name for logs"
  value       = aws_s3_bucket.logs.id
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for CloudWatch alerts (subscribe via: aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint your@email.com)"
  value       = aws_sns_topic.alerts.arn
}

output "sns_billing_alerts_topic_arn" {
  description = "SNS topic ARN for billing alerts (subscribe via: aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint your@email.com)"
  value       = aws_sns_topic.billing_alerts.arn
}
