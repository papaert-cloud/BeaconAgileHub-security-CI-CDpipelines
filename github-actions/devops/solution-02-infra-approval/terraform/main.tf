terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 artifact bucket (versioned + encryption)
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifact_bucket
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.artifacts.arn
      }
    }
  }
  versioning {
    enabled = true
  }
}

# KMS key for signing/artifacts
resource "aws_kms_key" "artifacts" {
  description = "KMS key for GitHub Actions cosign and artifact encryption"
  policy      = data.aws_iam_policy_document.kms_policy.json
}

resource "aws_kms_alias" "key_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.artifacts.key_id
}

# ECR repo (example)
resource "aws_ecr_repository" "app" {
  name                 = "sbom-security-pipeline"
  image_tag_mutability = "MUTABLE"
}

# IAM role for GitHub Actions to push to ECR
resource "aws_iam_role" "github_ecr_push" {
  name               = "GitHubActionsECRPush-${var.account_id}"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
}

resource "aws_iam_policy" "ecr_push_policy" {
  name   = "GitHub_ECR_Push_${var.account_id}"
  policy = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr_push" {
  role       = aws_iam_role.github_ecr_push.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Optionally restrict to specific repository and sub/path using `sub` claim
    # See README for recommended repo restriction
  }
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  statement {
    actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.artifacts.arn]
  }
}

# Example data for KMS policy (restrict to account principals)

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
