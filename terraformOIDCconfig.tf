provider "aws" {
  region = "us-east-1"
}
variable "artifact_bucket" {
  description = "Optional: S3 bucket name for artifacts. If set, module will attach a PutObject policy to the role."
  type        = string
  default     = ""
}
module "github_oidc" {
  source               = "./modules/oidc-github"
  create_oidc_provider = false # Use existing provider
  account_id           = "005965605891"
  aws_region           = "us-east-1"
  github_repo          = "papaert-cloud/peter-security-CI-CDpipelines"
  role_name            = "GitHubActionsOIDCRole"
  github_sub_suffix    = "*"

  # S3 permissions for artifact storage
  attach_s3_bucket = var.artifact_bucket

  # ECR permissions for container image push/pull
  attach_ecr_repositories = [
    "my-app",
    "demo-app",
    "secure-app"
  ]

  # KMS permissions for image signing
  attach_kms_key_arns = [
    "arn:aws:kms:us-east-1:005965605891:key/*" # Replace with actual key ARNs
  ]

  # Security Hub permissions for findings ingestion
  enable_securityhub = true

  # Terraform state management permissions
  attach_terraform_state_bucket = "terraform-state-bucket-005965605891"
  attach_tfstate_dynamodb_table = "terraform-state-lock"

  # Comprehensive Terraform infrastructure management
  enable_terraform_infrastructure = true
}

output "oidc_provider_arn" {
  value       = module.github_oidc.oidc_provider_arn
  description = "ARN of the GitHub Actions OIDC provider (existing or created)"
}

output "github_oidc_role_arn" {
  value       = module.github_oidc.role_arn
  description = "ARN of the IAM role GitHub Actions can assume via OIDC"
}


