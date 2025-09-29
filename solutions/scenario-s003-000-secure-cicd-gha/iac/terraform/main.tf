terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# OIDC IdP for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Keep the thumbprint list configurable; rotate as needed
  thumbprint_list = var.github_oidc_thumbprints
}

# Build assume-role policy document restricted by audience and subject
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to repo refs and/or environments
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        [for b in var.allowed_refs : "repo:${var.github_owner}/${var.github_repo}:ref:${b}"],
        [for e in var.allowed_environments : "repo:${var.github_owner}/${var.github_repo}:environment:${e}"]
      )
    }
  }
}

resource "aws_iam_role" "gha_deployer" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = var.permissions_boundary_arn == "" ? null : var.permissions_boundary_arn
  max_session_duration = 3600
  path                 = "/github-actions/"
  tags                 = var.tags
}

# Example minimal policy for Terraform that manages S3 state + generic infra (customize per your modules)
data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid    = "StateBackend"
    effect = "Allow"
    actions = [
      "s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeReadCommon"
    effect = "Allow"
    actions = [
      "iam:GetRole", "iam:ListRolePolicies", "iam:GetPolicy", "iam:GetPolicyVersion",
      "ec2:Describe*", "cloudwatch:List", "cloudwatch:Describe"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_permissions" {
  name   = "${var.role_name}-policy"
  policy = data.aws_iam_policy_document.gha_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.gha_deployer.name
  policy_arn = aws_iam_policy.gha_permissions.arn
}
