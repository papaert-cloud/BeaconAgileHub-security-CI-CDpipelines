variable "create_oidc_provider" {
  type    = bool
  default = false
}

variable "account_id" {
  description = "AWS account id where the OIDC provider lives or should be created"
  type        = string
  default     = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repo owner/name (owner/repo)"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role to create"
  type        = string
  default     = "GitHubActionsOIDCRole"
}

variable "github_sub_suffix" {
  type    = string
  default = "*"
}

variable "attach_s3_bucket" {
  description = "If set, module will create a policy allowing PutObject to this bucket (name only)"
  type        = string
  default     = ""
}

variable "attach_ecr_repositories" {
  description = "Optional: list of ECR repository ARNs or names the role should be allowed to push/pull to. If names are provided they will be converted to ARNs using account_id and aws_region."
  type        = list(string)
  default     = []
}

variable "attach_kms_key_arns" {
  description = "Optional: list of KMS key ARNs the role needs access to (e.g., for image signing)."
  type        = list(string)
  default     = []
}

variable "enable_securityhub" {
  description = "Optional: if true, attach minimal Security Hub permissions needed to import findings."
  type        = bool
  default     = false
}

variable "attach_terraform_state_bucket" {
  description = "Optional: S3 bucket name used for Terraform state. When set, role will get read/write permissions needed for remote state operations."
  type        = string
  default     = ""
}

variable "attach_tfstate_dynamodb_table" {
  description = "Optional: DynamoDB table name used for Terraform state locking. When set, role will get DynamoDB permissions for locking."
  type        = string
  default     = ""
}

variable "enable_terraform_infrastructure" {
  description = "Optional: if true, attach comprehensive IAM permissions for Terraform infrastructure management"
  type        = bool
  default     = false
}
