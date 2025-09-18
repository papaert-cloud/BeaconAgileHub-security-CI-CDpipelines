variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "acme-corp"
}

variable "environment" {
  description = "Environment tier"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod", "shared"], var.environment)
    error_message = "Environment must be dev, staging, prod, or shared."
  }
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_multi_account" {
  description = "Enable multi-account deployment"
  type        = bool
  default     = false
}

variable "target_accounts" {
  description = "Target accounts for StackSet deployment"
  type = list(object({
    account_id  = string
    region      = string
    environment = string
    vpc_cidr    = string
  }))
  default = [
    {
      account_id  = "005965605891"
      region      = "us-east-1"
      environment = "management"
      vpc_cidr    = "10.10.0.0/16"
    },
    {
      account_id  = "058264377640"
      region      = "us-east-1"
      environment = "workload"
      vpc_cidr    = "10.20.0.0/16"
    }
  ]
}

variable "organizational_units" {
  description = "Organization unit IDs for service-managed StackSets"
  type        = list(string)
  default     = ["ou-root-1234567890", "ou-workloads-0987654321"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "enterprise-stackset"
    ManagedBy = "terraform"
    Owner     = "platform-team"
  }
}