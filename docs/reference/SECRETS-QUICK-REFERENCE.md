# Secrets Quick Reference

## Essential Repository Secrets

| Secret Name | Purpose | Example Value | Notes |
|-------------|---------|---------------|-------|
| `SONAR_TOKEN` | SonarQube authentication | `sqp_xxx...` | Required for code quality scans |
| `ARTIFACT_BUCKET` | S3 bucket for build artifacts | `my-org-artifacts` | Optional, set if using S3 storage |
| `LAMBDA_DEPLOY_BUCKET` | S3 bucket for Lambda packages | `my-lambda-deployments` | Required for Lambda deployments |

## Environment-Specific Secrets Template

Replace `ENVIRONMENT` with: `dev`, `sandbox`, `staging`, `uat`, or `prod`

| Secret Name | Value Template | Example |
|-------------|----------------|---------|
| `AWS_ACCOUNT_ID` | `[ACCOUNT_ID]` | `123456789012` |
| `AWS_REGION` | `us-east-1` | `us-east-1` |
| `ECR_REGISTRY` | `[ACCOUNT_ID].dkr.ecr.[REGION].amazonaws.com` | `123456789012.dkr.ecr.us-east-1.amazonaws.com` |
| `STATE_BUCKET` | `org-terraform-state-[ENVIRONMENT]` | `org-terraform-state-dev` |
| `DYNAMODB_TABLE` | `org-terraform-locks-[ENVIRONMENT]` | `org-terraform-locks-dev` |
| `KMS_KEY_ARN` | `arn:aws:kms:[REGION]:[ACCOUNT_ID]:key/[KEY_ID]` | `arn:aws:kms:us-east-1:123456789012:key/abc123...` |

## Current Account IDs in Workflows

These are currently hardcoded and should be moved to environment secrets:

- **Current Account**: `005965605891`
- **Current Region**: `us-east-1`

## Priority Setup Order

1. **Repository Secrets** (affects all environments)
   - `SONAR_TOKEN`
   - `ARTIFACT_BUCKET`

2. **Dev Environment** (for testing)
   - `AWS_ACCOUNT_ID`
   - `AWS_REGION`
   - `STATE_BUCKET`

3. **Other Environments** (staging, prod, etc.)
   - Copy dev pattern with environment-specific values

## Common Issues

- **Secret not found**: Check environment vs repository scope
- **AWS auth fails**: Verify OIDC role trust policy
- **Wrong environment**: Check workflow environment specification

## Links

- [Full Documentation](./SECRETS-MANAGEMENT.md)
- [Setup Guide](./GITHUB-SECRETS-SETUP.md)
- [IAM Examples](../../github-actions/devsecops/iam-examples/)
