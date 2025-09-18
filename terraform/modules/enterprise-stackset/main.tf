# Enterprise StackSet Module - Multi-Account Resource Provisioning

resource "aws_cloudformation_stack_set" "enterprise" {
  name             = "${var.org_name}-${var.environment}-stackset"
  description      = "Enterprise multi-account resource provisioning"
  permission_model = var.enable_multi_account ? "SERVICE_MANAGED" : "SELF_MANAGED"

  auto_deployment {
    enabled                          = var.enable_multi_account
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    OrgName            = var.org_name
    Environment        = var.environment
    Region             = var.aws_region
    VpcCidr            = var.vpc_cidr
    EnableMultiAccount = var.enable_multi_account ? "true" : "false"
  }

  template_body = file("${path.module}/enterprise-stackset.yaml")

  tags = merge(var.common_tags, {
    Name = "${var.org_name}-${var.environment}-stackset"
    Type = "StackSet"
  })
}

# StackSet Instances for target accounts (self-managed)
resource "aws_cloudformation_stack_set_instance" "accounts" {
  count = var.enable_multi_account ? 0 : length(var.target_accounts)

  stack_set_name = aws_cloudformation_stack_set.enterprise.name
  account_id     = var.target_accounts[count.index].account_id
  region         = var.target_accounts[count.index].region

  parameter_overrides = {
    Environment = var.target_accounts[count.index].environment
    VpcCidr     = var.target_accounts[count.index].vpc_cidr
  }

  depends_on = [aws_cloudformation_stack_set.enterprise]
}

# StackSet Instances for multi-account (service-managed)
resource "aws_cloudformation_stack_set_instance" "multi_account" {
  count = var.enable_multi_account ? length(var.target_accounts) : 0

  stack_set_name = aws_cloudformation_stack_set.org_managed[0].name
  account_id     = var.target_accounts[count.index].account_id
  region         = var.target_accounts[count.index].region

  parameter_overrides = {
    Environment = var.target_accounts[count.index].environment
    VpcCidr     = var.target_accounts[count.index].vpc_cidr
  }

  depends_on = [aws_cloudformation_stack_set.org_managed]
}

# Organizations integration for service-managed StackSets
resource "aws_cloudformation_stack_set" "org_managed" {
  count = var.enable_multi_account ? 1 : 0

  name             = "${var.org_name}-org-managed-stackset"
  description      = "Organization-managed StackSet"
  permission_model = "SERVICE_MANAGED"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    OrgName            = var.org_name
    Environment        = "shared"
    Region             = var.aws_region
    VpcCidr            = "10.100.0.0/16"
    EnableMultiAccount = "true"
  }

  template_body = file("${path.module}/enterprise-stackset.yaml")

  tags = merge(var.common_tags, {
    Name = "${var.org_name}-org-stackset"
    Type = "OrganizationStackSet"
  })
}

