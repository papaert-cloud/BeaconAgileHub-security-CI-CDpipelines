locals {
  github_sub = "repo:${var.github_repo}:${var.github_sub_suffix}"
}

data "aws_caller_identity" "current" {}

# Either create provider or reference existing
resource "aws_iam_openid_connect_provider" "maybe_create" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_openid_connect_provider" "existing" {
  # when provider already exists in account
  arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.maybe_create[0].arn : "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions_oidc" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "GitHubOIDCTrust",
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.existing.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud"              = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:repository"       = var.github_repo,
            "token.actions.githubusercontent.com:repository_owner" = split("/", var.github_repo)[0]
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_sub
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_put_object" {
  count = var.attach_s3_bucket != "" ? 1 : 0

  name        = "GitHubActionsS3PutObject-${replace(var.attach_s3_bucket, "-", "-")}"
  description = "Allow GitHub Actions role to write artifacts to the given S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = ["arn:aws:s3:::${var.attach_s3_bucket}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3" {
  count      = var.attach_s3_bucket != "" ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.s3_put_object[0].arn
}

/* ECR push/pull policy - optional */
resource "aws_iam_policy" "ecr_push_pull" {
  count = length(var.attach_ecr_repositories) > 0 ? 1 : 0

  name        = "GitHubActionsECRPushPull-${aws_iam_role.github_actions_oidc.name}"
  description = "Allow GitHub Actions role to push and pull images to specified ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = length(var.attach_ecr_repositories) > 0 ? [for repo in var.attach_ecr_repositories :
          startswith(repo, "arn:") ? repo : "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${repo}"
        ] : ["*"]
      },
      {
        Effect   = "Allow",
        Action   = ["ecr:DescribeRepositories", "ecr:GetRepositoryPolicy", "ecr:ListImages"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  count      = length(var.attach_ecr_repositories) > 0 ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.ecr_push_pull[0].arn
}

/* KMS usage policy for image signing / encryption */
resource "aws_iam_policy" "kms_access" {
  count = length(var.attach_kms_key_arns) > 0 ? 1 : 0

  name        = "GitHubActionsKMSUse-${aws_iam_role.github_actions_oidc.name}"
  description = "Allow use of specific KMS keys (Encrypt/Decrypt/GenerateDataKey/Sign)"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:Sign",
          "kms:Verify"
        ],
        Resource = var.attach_kms_key_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kms" {
  count      = length(var.attach_kms_key_arns) > 0 ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.kms_access[0].arn
}

/* Security Hub minimal ingestion permissions */
resource "aws_iam_policy" "securityhub_ingest" {
  count = var.enable_securityhub ? 1 : 0

  name        = "GitHubActionsSecurityHubIngest-${aws_iam_role.github_actions_oidc.name}"
  description = "Allow minimal Security Hub permissions to import findings"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "securityhub:BatchImportFindings",
          "securityhub:CreateActionTarget",
          "securityhub:UpdateFindings",
          "securityhub:GetFindings",
          "securityhub:DescribeProducts"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_securityhub" {
  count      = var.enable_securityhub ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.securityhub_ingest[0].arn
}

/* Terraform remote state S3 and DynamoDB permissions (optional) */
resource "aws_iam_policy" "terraform_state_s3" {
  count = var.attach_terraform_state_bucket != "" ? 1 : 0

  name        = "GitHubActionsTerraformStateS3-${aws_iam_role.github_actions_oidc.name}"
  description = "Allow GitHub Actions role to read/write Terraform state in S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.attach_terraform_state_bucket}",
          "arn:aws:s3:::${var.attach_terraform_state_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_tfstate_s3" {
  count      = var.attach_terraform_state_bucket != "" ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.terraform_state_s3[0].arn
}

resource "aws_iam_policy" "terraform_state_dynamodb" {
  count = var.attach_tfstate_dynamodb_table != "" ? 1 : 0

  name        = "GitHubActionsTerraformStateDDB-${aws_iam_role.github_actions_oidc.name}"
  description = "Allow GitHub Actions role to perform DynamoDB locking for Terraform state"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ],
        Resource = ["arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.attach_tfstate_dynamodb_table}"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_tfstate_dynamodb" {
  count      = var.attach_tfstate_dynamodb_table != "" ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.terraform_state_dynamodb[0].arn
}

/* Comprehensive Terraform Infrastructure Management Policy */
resource "aws_iam_policy" "terraform_infrastructure" {
  count = var.enable_terraform_infrastructure ? 1 : 0

  name        = "GitHubActionsTerraformInfra-${aws_iam_role.github_actions_oidc.name}"
  description = "Comprehensive permissions for Terraform infrastructure management"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "vpc:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:ListAliases",
          "kms:ListKeys"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_terraform_infrastructure" {
  count      = var.enable_terraform_infrastructure ? 1 : 0
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = aws_iam_policy.terraform_infrastructure[0].arn
}

// Outputs moved to `outputs.tf` to keep module outputs centralized.
