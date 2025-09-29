terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Management account provider — run this in the org management account or set assume role
  region = var.region
}

########################################
# Organization SCP to deny public bucket ACLs
########################################
resource "aws_organizations_policy" "deny_public_s3_acls" {
  name        = "DenyPublicS3ACLs"
  description = "Deny creating public S3 ACLs across the org"
  type        = "SERVICE_CONTROL_POLICY"

  content = <<POL
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "DenyPublicS3Acls",
        "Effect": "Deny",
        "Action": [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl"
        ],
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
          }
        }
      }
    ]
  }
  POL
}

resource "aws_organizations_policy_attachment" "attach_deny_public_s3" {
  policy_id = aws_organizations_policy.deny_public_s3_acls.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_organizations_organization" "this" {}

########################################
# AWS Config Organization Aggregator and Rules
########################################
resource "aws_config_configuration_aggregator" "org_aggregator" {
  name = "org-aggregator"

  organization_aggregation_source {
    role_arn    = var.config_aggregator_role_arn
    aws_regions = [var.region]
  }
}

resource "aws_config_organization_managed_rule" "s3_public_read_prohibited" {
  name              = "s3-bucket-public-read-prohibited"
  rule_identifier   = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  excluded_accounts = var.excluded_accounts
}

resource "aws_config_organization_managed_rule" "s3_public_write_prohibited" {
  name              = "s3-bucket-public-write-prohibited"
  rule_identifier   = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  excluded_accounts = var.excluded_accounts
}

########################################
# EventBridge rule to catch Config Compliance change and SNS topic
########################################
resource "aws_sns_topic" "s3_public_alerts" {
  name = "s3-public-alerts"
}

resource "aws_cloudwatch_event_rule" "config_compliance_changes" {
  name = "config-compliance-changes"

  event_pattern = <<PAT
  {
    "source": ["aws.config"],
    "detail-type": ["Config Rules Compliance Change"]
  }
  PAT
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule = aws_cloudwatch_event_rule.config_compliance_changes.name
  arn  = aws_sns_topic.s3_public_alerts.arn
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.s3_public_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

