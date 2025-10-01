resource "aws_budgets_budget" "monthly_cost_budget" {
  name         = "monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = "10"  # $10/month limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filter {
    name   = "Service"
    values = [
      "Amazon Elastic Compute Cloud - Compute",
      "Amazon Elastic Block Store", 
      "Amazon Virtual Private Cloud"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["${var.alert_email}"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["${var.alert_email}"]
  }
}

# Cost anomaly detection
resource "aws_ce_anomaly_detector" "cost_anomaly" {
  name         = "cost-anomaly-detector"
  monitor_type = "DIMENSIONAL"

  specification = jsonencode({
    Dimension = "SERVICE"
    Key       = "SERVICE"
    Values    = ["EC2-Instance", "EC2-Other"]
  })
}

# CloudWatch billing alarm
resource "aws_cloudwatch_metric_alarm" "high_billing" {
  alarm_name          = "high-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600"  # 6 hours
  statistic           = "Maximum"
  threshold           = "15.00"   # $15 threshold
  alarm_description   = "This metric monitors AWS billing charges"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }
}

resource "aws_sns_topic" "billing_alerts" {
  name = "billing-alerts"
}

variable "alert_email" {
  description = "Email for billing alerts"
  type        = string
  default     = "admin@example.com"
}