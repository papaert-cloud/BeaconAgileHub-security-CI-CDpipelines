output "stackset_id" {
  description = "StackSet ID"
  value       = aws_cloudformation_stack_set.enterprise.id
}

output "stackset_arn" {
  description = "StackSet ARN"
  value       = aws_cloudformation_stack_set.enterprise.arn
}

output "stackset_name" {
  description = "StackSet name"
  value       = aws_cloudformation_stack_set.enterprise.name
}

output "stack_instances" {
  description = "Stack instance details"
  value = concat(
    [
      for instance in aws_cloudformation_stack_set_instance.accounts : {
        account_id = instance.account_id
        region     = instance.region
        stack_id   = instance.stack_id
      }
    ],
    [
      for instance in aws_cloudformation_stack_set_instance.multi_account : {
        account_id = instance.account_id
        region     = instance.region
        stack_id   = instance.stack_id
      }
    ]
  )
}

output "org_stackset_id" {
  description = "Organization StackSet ID"
  value       = var.enable_multi_account ? aws_cloudformation_stack_set.org_managed[0].id : null
}

output "multi_account_instances" {
  description = "Multi-account stack instances"
  value = [
    for instance in aws_cloudformation_stack_set_instance.multi_account : {
      account_id = instance.account_id
      region     = instance.region
      stack_id   = instance.stack_id
    }
  ]
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    total_accounts     = length(var.target_accounts)
    multi_account      = var.enable_multi_account
    primary_region     = var.aws_region
    organization_units = var.organizational_units
  }
}