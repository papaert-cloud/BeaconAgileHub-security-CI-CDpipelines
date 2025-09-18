# Global Terragrunt Configuration - DRY Infrastructure Management

locals {
  # Parse environment from path
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment      = local.environment_vars.locals.environment
  
  # Common tags for all resources
  common_tags = {
    Environment     = local.environment
    Project         = "sbom-security-pipeline"
    ManagedBy      = "terragrunt"
    ICSCompliance  = "true"
    SecurityLevel  = local.environment == "production" ? "critical" : "standard"
  }
  
  # AWS Account mapping
  account_mapping = {
    dev        = "123456789012"  # Replace with actual dev account
    staging    = "123456789013"  # Replace with actual staging account  
    production = "123456789014"  # Replace with actual prod account
    shared     = "123456789015"  # Replace with actual shared services account
  }
}

# Configure Terraform backend
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-state-${local.environment}-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-${local.environment}"
    
    # Enable versioning and MFA delete for production
    versioning = local.environment == "production" ? true : false
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::${local.account_mapping[local.environment]}:role/TerraformExecutionRole"
  }
  
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# Generate common variables
generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "${local.environment}"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "sbom-security-pipeline"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = ${jsonencode(local.common_tags)}
}
EOF
}

# Input values for all modules
inputs = {
  environment   = local.environment
  project_name  = "sbom-security-pipeline"
  aws_region    = "us-east-1"
  common_tags   = local.common_tags
}