include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "../../../../terraform/modules/enterprise-stackset"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
EOF
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  org_name             = "acme-corp"
  environment          = "shared"
  aws_region           = "us-east-1"
  vpc_cidr            = "10.100.0.0/16"
  enable_multi_account = true
  
  target_accounts = [
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
  
  organizational_units = [
    "ou-im88-1fmr1yt9"
  ]
  
  common_tags = merge(local.env_vars.locals.common_tags, {
    Component = "enterprise-stackset"
    Scope     = "multi-account"
  })
}