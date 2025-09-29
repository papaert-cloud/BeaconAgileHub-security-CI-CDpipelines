output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (existing or created)"
  value       = var.create_oidc_provider ? aws_iam_openid_connect_provider.maybe_create[0].arn : data.aws_iam_openid_connect_provider.existing.arn
}

output "role_arn" {
  description = "ARN of the created role"
  value       = aws_iam_role.github_actions_oidc.arn
}

output "role_name" {
  description = "Name of the created role"
  value       = aws_iam_role.github_actions_oidc.name
}
