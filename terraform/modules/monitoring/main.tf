# Comprehensive Monitoring Module - CloudWatch Integration
# Implements ICS continuous monitoring principles with real-time alerting

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
  }
}

# CloudWatch Dashboard for DevSecOps Pipeline Overview
resource "aws_cloudwatch_dashboard" "devsecops_overview" {
  dashboard_name = "${var.environment}-devsecops-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["DevSecOps/Security", "VulnerabilitiesFound", "Environment", var.environment],
            ["DevSecOps/Security", "SecurityGatesPassed", "Environment", var.environment],
            ["DevSecOps/Security", "SecurityGatesFailed", "Environment", var.environment]
          ]
          view    = "timeSeries"
          region  = data.aws_region.current.name
          title   = "Security Pipeline Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_request_count", "cluster_name", "${var.environment}-eks-cluster"],
            ["AWS/EKS", "cluster_node_count", "cluster_name", "${var.environment}-eks-cluster"]
          ]
          view    = "timeSeries"
          region  = data.aws_region.current.name
          title   = "EKS Cluster Health"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query = "SOURCE '/aws/securityhub/findings' | fields @timestamp, @message | filter @message like /CRITICAL/ | sort @timestamp desc | limit 20"
          region = data.aws_region.current.name
          title = "Recent Critical Security Events"
        }
      }
    ]
  })
}

# Custom Metrics for Security Events
resource "aws_cloudwatch_log_metric_filter" "security_events" {
  name           = "${var.environment}-security-events"
  log_group_name = "/aws/lambda/${var.environment}-security-scanner"
  pattern        = "[timestamp, request_id=\"SECURITY\", event_type, severity, ...]"

  metric_transformation {
    name      = "SecurityEvents"
    namespace = "DevSecOps/Security"
    value     = "1"
    dimensions = {
      Environment = var.environment
      EventType   = "$event_type"
      Severity    = "$severity"
    }
  }
}

# Critical Security Alarm
resource "aws_cloudwatch_metric_alarm" "critical_security_events" {
  alarm_name          = "${var.environment}-critical-security-events"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityEvents"
  namespace           = "DevSecOps/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Critical security events detected in ${var.environment}"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    Severity    = "CRITICAL"
  }
}

# SNS Topics for Alert Routing
resource "aws_sns_topic" "critical_alerts" {
  name         = "${var.environment}-critical-security-alerts"
  display_name = "Critical Security Alerts - ${var.environment}"
  kms_master_key_id = aws_kms_key.sns_encryption.arn
}

resource "aws_sns_topic" "security_alerts" {
  name         = "${var.environment}-security-alerts"
  display_name = "Security Alerts - ${var.environment}"
  kms_master_key_id = aws_kms_key.sns_encryption.arn
}

# KMS Key for SNS Encryption
resource "aws_kms_key" "sns_encryption" {
  description             = "KMS key for SNS topic encryption in ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Lambda Function for Alert Processing
resource "aws_lambda_function" "alert_processor" {
  filename         = data.archive_file.alert_processor.output_path
  function_name    = "${var.environment}-alert-processor"
  role            = aws_iam_role.alert_processor_role.arn
  handler         = "alert_processor.lambda_handler"
  source_code_hash = data.archive_file.alert_processor.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

# Alert Processor Lambda Code
data "archive_file" "alert_processor" {
  type        = "zip"
  output_path = "/tmp/alert_processor.zip"
  
  source {
    content = <<-EOF
import json
import boto3
import urllib3
import os
from datetime import datetime

def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = message['AlarmName']
    new_state = message['NewStateValue']
    
    alert_data = {
        "alarm": alarm_name,
        "state": new_state,
        "timestamp": datetime.utcnow().isoformat(),
        "environment": os.environ['ENVIRONMENT'],
        "severity": determine_severity(alarm_name, new_state)
    }
    
    if os.environ.get('SLACK_WEBHOOK_URL'):
        send_slack_alert(alert_data)
    
    print(f"SECURITY_ALERT: {json.dumps(alert_data)}")
    return {'statusCode': 200}

def determine_severity(alarm_name, state):
    if 'critical' in alarm_name.lower() and state == 'ALARM':
        return 'CRITICAL'
    elif 'security' in alarm_name.lower() and state == 'ALARM':
        return 'HIGH'
    return 'MEDIUM'

def send_slack_alert(alert_data):
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    if not webhook_url:
        return
    
    slack_message = {
        "text": f"🚨 {alert_data['severity']} Alert: {alert_data['alarm']}",
        "attachments": [{
            "color": "danger" if alert_data['severity'] == 'CRITICAL' else "warning",
            "fields": [
                {"title": "Environment", "value": alert_data['environment'], "short": True},
                {"title": "State", "value": alert_data['state'], "short": True}
            ]
        }]
    }
    
    try:
        http = urllib3.PoolManager()
        http.request('POST', webhook_url, body=json.dumps(slack_message), headers={'Content-Type': 'application/json'})
    except Exception as e:
        print(f"Error sending Slack notification: {e}")
EOF
    filename = "alert_processor.py"
  }
}

# IAM Role for Alert Processor
resource "aws_iam_role" "alert_processor_role" {
  name = "${var.environment}-alert-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alert_processor_basic" {
  role       = aws_iam_role.alert_processor_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SNS Subscriptions
resource "aws_sns_topic_subscription" "alert_processor" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_processor.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.critical_alerts.arn
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}