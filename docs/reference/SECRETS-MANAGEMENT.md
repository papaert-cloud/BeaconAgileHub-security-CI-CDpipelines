# Secrets Management Guide

This document defines all required secrets across environments for the GitHub Actions workflows and provides guidance on setting them up.

## Overview

Our secrets are organized in three tiers:

1. **Repository Secrets** - Shared across all environments
2. **Environment Secrets** - Specific to each environment (dev, staging, prod, sandbox, uat)
3. **Organization Secrets** - Shared across multiple repositories (if applicable)

## Environment Structure

- **dev** - Development environment for active authoring and experimentation
- **sandbox** - Integration testing and smoke tests
- **staging** - Pre-production validation, mirrors production settings
- **uat** - User acceptance testing
- **prod** - Production environment with strict change controls

## Repository Secrets (Global)

These secrets are used across all environments and workflows:

### Security and Code Analysis

| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `SONAR_TOKEN` | SonarQube/SonarCloud authentication token | `sonar-scan.yml` | `sqp_xxx...` |
| `SEMGREP_APP_TOKEN` | Semgrep authentication token | `semgrep-scan.yml` | `xxx...` |
| `SNYK_TOKEN` | Snyk authentication token | Security scanning | `xxx...` |
| `GITHUB_TOKEN` | GitHub token (auto-provided) | CodeQL, various workflows | Auto-generated |

### Container Registry and Signing

| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `DOCKERHUB_USERNAME` | Docker Hub username | Container operations | `myuser` |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Container operations | `dckr_pat_xxx...` |

### General Configuration

| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `ARTIFACT_BUCKET` | S3 bucket for storing build artifacts | `sbom-sca.yml` | `my-org-artifacts` |
| `LAMBDA_DEPLOY_BUCKET` | S3 bucket for Lambda deployment packages | `secure-cicd-gha-deploy.yml` | `my-lambda-deployments` |

## Environment-Specific Secrets

Each environment should have its own set of these secrets to ensure proper isolation:

### AWS Configuration (Per Environment)

| Secret Name | Description | Dev Value | Staging Value | Prod Value |
|-------------|-------------|-----------|---------------|------------|
| `AWS_ACCOUNT_ID` | AWS Account ID | `111111111111` | `222222222222` | `333333333333` |
| `AWS_REGION` | Primary AWS region | `us-east-1` | `us-east-1` | `us-east-1` |
| `AWS_ROLE_ARN` | OIDC role ARN for GitHub Actions | `arn:aws:iam::111111111111:role/GitHubActionsOIDCRole` | `arn:aws:iam::222222222222:role/GitHubActionsOIDCRole` | `arn:aws:iam::333333333333:role/GitHubActionsOIDCRole` |

### Environment-Specific Resources

| Secret Name | Description | Dev Value | Staging Value | Prod Value |
|-------------|-------------|-----------|---------------|------------|
| `ECR_REGISTRY` | ECR registry URL | `111111111111.dkr.ecr.us-east-1.amazonaws.com` | `222222222222.dkr.ecr.us-east-1.amazonaws.com` | `333333333333.dkr.ecr.us-east-1.amazonaws.com` |
| `KMS_KEY_ARN` | KMS key for signing/encryption | `arn:aws:kms:us-east-1:111111111111:key/xxx` | `arn:aws:kms:us-east-1:222222222222:key/xxx` | `arn:aws:kms:us-east-1:333333333333:key/xxx` |
| `STATE_BUCKET` | Terraform state bucket | `org-terraform-state-dev` | `org-terraform-state-staging` | `org-terraform-state-prod` |
| `DYNAMODB_TABLE` | Terraform state locking table | `org-terraform-locks-dev` | `org-terraform-locks-staging` | `org-terraform-locks-prod` |

### Infrastructure Access

| Secret Name | Description | Purpose |
|-------------|-------------|---------|
| `INFRACOST_API_KEY` | InfraCost API key for cost estimation | Cost analysis in terraform workflows |
| `TF_VAR_*` | Terraform variables (as needed) | Pass sensitive terraform variables |

## Current Workflow Secret Usage

### Analysis of Existing Workflows

1. **CodeQL Analysis** (`codeql-analysis.yml`)
   - Uses: `GITHUB_TOKEN` (auto-provided)

2. **SBOM/SCA** (`sbom-sca.yml`)
   - Uses: `ARTIFACT_BUCKET` (optional)
   - Environment variables: `AWS_ACCOUNT_ID`, `AWS_REGION`

3. **SonarQube Scan** (`sonar-scan.yml`)
   - Uses: `SONAR_TOKEN`

4. **Secure CI/CD Deploy** (`secure-cicd-gha-deploy.yml`)
   - Uses: `LAMBDA_DEPLOY_BUCKET`

5. **Container Signing** (`sign-and-push.yml`)
   - Environment variables: `AWS_ACCOUNT_ID`, `AWS_REGION`
   - Uses OIDC for AWS authentication

## Secret Naming Conventions

### Repository Secrets

- Use UPPER_CASE with underscores
- Be descriptive but concise
- Include service/tool name prefix when applicable

### Environment Variables in Workflows

- Use `env:` section in workflows for non-sensitive environment-specific values
- Keep sensitive values in secrets
- Use consistent naming across environments

## Security Best Practices

### Secret Management

1. **Principle of Least Privilege**: Only grant access to secrets that are absolutely necessary
2. **Environment Isolation**: Use different secrets for each environment
3. **Regular Rotation**: Rotate secrets regularly, especially long-lived tokens
4. **Audit Access**: Monitor secret usage and access patterns

### OIDC Configuration

- Use OpenID Connect (OIDC) for AWS authentication where possible
- Avoid long-lived AWS access keys
- Configure trust policies with appropriate conditions (repository, branch, etc.)

### Secret Scope

- **Repository secrets**: For non-environment-specific values
- **Environment secrets**: For environment-specific values
- **Organization secrets**: For values shared across multiple repositories

## Migration Strategy

### Current State

Currently using hardcoded environment variables in workflows:

```yaml
env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: 005965605891
```

### Recommended Approach

1. Move environment-specific values to GitHub environment secrets
2. Keep common values as repository secrets
3. Use environment protection rules for production deployments

### Implementation Steps

1. Create GitHub environments (dev, staging, prod, sandbox, uat)
2. Configure environment-specific secrets
3. Update workflows to use environment-specific values
4. Test in dev environment first
5. Gradually roll out to other environments

## Next Steps

1. **Immediate Actions**:
   - Set up GitHub environments
   - Configure repository secrets
   - Update workflows to use secrets instead of hardcoded values

2. **Environment Setup**:
   - Configure environment-specific secrets
   - Set up environment protection rules
   - Test deployment pipelines

3. **Security Enhancements**:
   - Implement secret rotation policies
   - Set up monitoring and alerting
   - Review and audit access permissions

## Related Documentation

- [Environment Setup Guide](../environments/ENVIRONMENTS-README.md)
- [GitHub Actions Workflows](../../.github/workflows/)
- [IAM Examples](../../github-actions/devsecops/iam-examples/)
- [Terraform Configuration](../../Infra/)

## Troubleshooting

### Common Issues

1. **Secret not found**: Verify secret name matches exactly in workflow
2. **Access denied**: Check OIDC role trust policy and permissions
3. **Environment not found**: Ensure environment is created in repository settings

### Debug Steps

1. Check GitHub Actions logs for specific error messages
2. Verify secret names and scopes
3. Test OIDC role assumption manually
4. Review IAM policies and trust relationships
