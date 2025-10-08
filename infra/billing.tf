# SNS topic for billing alerts
resource "aws_sns_topic" "billing_alerts" {
  name         = "couetil-com-billing-alerts"
  display_name = "Billing alerts for www.couetil.com"
}

# CloudWatch alarm for monthly spend - $10 threshold
resource "aws_cloudwatch_metric_alarm" "billing_alarm_10" {
  alarm_name          = "billing-alert-10-dollars"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours
  statistic           = "Maximum"
  threshold           = 10.0
  alarm_description   = "This metric monitors estimated monthly charges and triggers at $10"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}

# CloudWatch alarm for monthly spend - $25 threshold
resource "aws_cloudwatch_metric_alarm" "billing_alarm_25" {
  alarm_name          = "billing-alert-25-dollars"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours
  statistic           = "Maximum"
  threshold           = 25.0
  alarm_description   = "This metric monitors estimated monthly charges and triggers at $25"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}

# CloudWatch alarm for monthly spend - $50 threshold
resource "aws_cloudwatch_metric_alarm" "billing_alarm_50" {
  alarm_name          = "billing-alert-50-dollars"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours
  statistic           = "Maximum"
  threshold           = 50.0
  alarm_description   = "This metric monitors estimated monthly charges and triggers at $50"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}
