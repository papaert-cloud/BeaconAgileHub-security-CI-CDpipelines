variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_id" {
  type = string
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider in this account (create via Terraform or console)"
}

variable "github_repo" {
  type        = string
  description = "Full repo identifier, e.g., bamg-studio/sbom-security-pipeline"
}

variable "artifact_bucket" {
  type = string
}

variable "kms_key_alias" {
  type    = string
  default = "alias/github-actions-cosign"
}
