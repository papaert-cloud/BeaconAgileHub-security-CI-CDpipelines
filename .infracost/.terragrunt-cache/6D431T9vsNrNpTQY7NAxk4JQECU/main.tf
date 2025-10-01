terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_iam_policy_document" "stackset_assume_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "stackset_execution_role" {
  name               = var.stackset_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.stackset_assume_policy.json
}

resource "aws_iam_policy" "stackset_exec_policy" {
  name        = "${var.stackset_execution_role_name}-policy"
  description = "Policy granting permissions required by StackSet-executed resources"
  policy      = file("${path.module}/../iam/stackset-execution-policy.json")
}

resource "aws_iam_role_policy_attachment" "attach_exec" {
  role       = aws_iam_role.stackset_execution_role.name
  policy_arn = aws_iam_policy.stackset_exec_policy.arn
}

resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = var.lambda_code_bucket
  # Using default ACLs and recommended settings is preferred; configure encryption & block public access outside this example
}

resource "aws_cloudformation_stack_set" "example" {
  name                    = var.stackset_name
  administration_role_arn = var.administration_role_arn
  execution_role_name     = aws_iam_role.stackset_execution_role.name

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = []

  template_body = file("${path.module}/../cf/stackset.yaml")
}


# NOTE: StackSet instances (per-account/per-region deployments) are provider-version sensitive.
# Different AWS provider versions accept either `account`/`region` attributes or a `deployment_targets` block.
# To avoid coupling this example to a specific provider schema, create stack set instances separately
# using either Terraform resources or the Console/AWS CLI. Example AWS CLI command to create instances:
#
# aws cloudformation create-stack-instances --stack-set-name ${aws_cloudformation_stack_set.example.name} --accounts 111111111111 --regions us-east-1
#
output "stackset_name" {
  value = aws_cloudformation_stack_set.example.name
}

