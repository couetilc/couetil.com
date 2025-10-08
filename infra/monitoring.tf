# SNS topic for CloudWatch alarms
resource "aws_sns_topic" "alerts" {
  name         = "couetil-com-alerts"
  display_name = "Alerts for www.couetil.com"
}

# CloudWatch alarm for CloudFront 4xx errors
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "cloudfront-4xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 5.0 # 5% error rate
  alarm_description   = "This metric monitors CloudFront 4xx error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }
}

# CloudWatch alarm for CloudFront 5xx errors
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "cloudfront-5xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 1.0 # 1% error rate
  alarm_description   = "This metric monitors CloudFront 5xx error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }
}

# CloudWatch alarm for CloudFront origin latency
resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_latency" {
  alarm_name          = "cloudfront-origin-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 1000 # 1 second in milliseconds
  alarm_description   = "This metric monitors CloudFront origin latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }
}

# Local exec to remind user to subscribe to SNS topics after apply
resource "null_resource" "sns_subscription_reminder" {
  # This will run after SNS topics are created/updated
  triggers = {
    alerts_topic  = aws_sns_topic.alerts.arn
    billing_topic = aws_sns_topic.billing_alerts.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "⚠️  ACTION REQUIRED: Subscribe to SNS Alert Topics"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "To receive CloudWatch and billing alerts, run:"
      echo ""
      echo "  ./subscribe-to-alerts.sh your@email.com"
      echo ""
      echo "Or manually subscribe using:"
      echo ""
      echo "  terraform output sns_alerts_topic_arn"
      echo "  terraform output sns_billing_alerts_topic_arn"
      echo ""
      echo "See README.md for detailed instructions."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
    EOT
  }
}
