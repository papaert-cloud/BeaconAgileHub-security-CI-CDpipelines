# Security Hub Integration Module
# Centralizes security findings and compliance monitoring

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
  }
}

# Enable Security Hub
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
}

# Subscribe to security standards
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0"
  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on = [aws_securityhub_account.main]
}

# Security Hub Dashboard
resource "aws_cloudwatch_dashboard" "security_hub_overview" {
  dashboard_name = "${var.environment}-security-hub-overview"

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
            ["AWS/SecurityHub", "Findings", "ComplianceType", "CRITICAL"],
            ["AWS/SecurityHub", "Findings", "ComplianceType", "HIGH"],
            ["AWS/SecurityHub", "Findings", "ComplianceType", "MEDIUM"]
          ]
          view    = "timeSeries"
          region  = data.aws_region.current.name
          title   = "Security Hub Findings by Severity"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 8
        properties = {
          query = "SOURCE '/aws/securityhub/findings' | fields @timestamp, @message | filter @message like /FAILED/ | stats count() as failed_controls by bin(1h) | sort @timestamp desc"
          region = data.aws_region.current.name
          title = "Failed Security Controls (Last 24 Hours)"
        }
      }
    ]
  })
}

# EventBridge Rule for Security Hub findings
resource "aws_cloudwatch_event_rule" "security_hub_findings" {
  name        = "${var.environment}-security-hub-findings"
  description = "Capture Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Compliance = {
          Status = ["FAILED"]
        }
        Severity = {
          Label = ["HIGH", "CRITICAL"]
        }
      }
    }
  })
}

# EventBridge target for Security Hub findings
resource "aws_cloudwatch_event_target" "security_hub_lambda" {
  rule      = aws_cloudwatch_event_rule.security_hub_findings.name
  target_id = "SecurityHubFindingsProcessor"
  arn       = aws_lambda_function.security_hub_processor.arn
}

# Lambda function for Security Hub findings processing
resource "aws_lambda_function" "security_hub_processor" {
  filename         = data.archive_file.security_hub_processor.output_path
  function_name    = "${var.environment}-security-hub-processor"
  role            = aws_iam_role.security_hub_processor_role.arn
  handler         = "security_hub_processor.lambda_handler"
  source_code_hash = data.archive_file.security_hub_processor.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      ENVIRONMENT = var.environment
      SNS_TOPIC_ARN = var.security_alerts_topic_arn
    }
  }
}

# Security Hub processor Lambda code
data "archive_file" "security_hub_processor" {
  type        = "zip"
  output_path = "/tmp/security_hub_processor.zip"
  
  source {
    content = <<-EOF
import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    sns = boto3.client('sns')
    
    finding = event['detail']['findings'][0]
    finding_id = finding['Id']
    title = finding['Title']
    severity = finding['Severity']['Label']
    
    alert_data = {
        "finding_id": finding_id,
        "title": title,
        "severity": severity,
        "timestamp": datetime.utcnow().isoformat(),
        "environment": os.environ['ENVIRONMENT']
    }
    
    try:
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Message=json.dumps(alert_data, indent=2),
            Subject=f"🚨 {severity} Security Finding: {title}"
        )
    except Exception as e:
        print(f"Error sending alert: {e}")
    
    print(f"SECURITY_FINDING: {json.dumps(alert_data)}")
    return {'statusCode': 200}
EOF
    filename = "security_hub_processor.py"
  }
}

# IAM Role for Security Hub processor
resource "aws_iam_role" "security_hub_processor_role" {
  name = "${var.environment}-security-hub-processor-role"

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

resource "aws_iam_role_policy" "security_hub_processor_policy" {
  name = "${var.environment}-security-hub-processor-policy"
  role = aws_iam_role.security_hub_processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = var.security_alerts_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:BatchUpdateFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_hub_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_findings.arn
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}