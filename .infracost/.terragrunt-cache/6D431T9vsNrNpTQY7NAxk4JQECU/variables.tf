variable "region" {
  description = "AWS region for StackSet operations"
  type        = string
  default     = "us-east-1"
}

variable "stackset_name" {
  description = "Name of the CloudFormation StackSet"
  type        = string
  default     = "secure-cicd-guardrails-stackset"
}

variable "stackset_execution_role_name" {
  description = "Name for the role that StackSet-created resources will assume"
  type        = string
  default     = "StackSetExecutionRole"
}

variable "administration_role_arn" {
  description = "ARN of the administration role used to manage the StackSet"
  type        = string
}

variable "lambda_code_bucket" {
  description = "S3 bucket where Lambda code zip is uploaded"
  type        = string
}

variable "target_account_ids" {
  description = "List of AWS account IDs where StackSet instances will be created"
  type        = list(string)
  default     = []
}
