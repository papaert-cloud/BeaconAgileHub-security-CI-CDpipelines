# GitHub Secrets Setup Guide

This guide provides step-by-step instructions for setting up secrets in your GitHub repository based on the [Secrets Management Guide](./SECRETS-MANAGEMENT.md).

## Prerequisites

- Repository administrator access
- AWS account access with appropriate permissions
- Understanding of your environment structure

## Step 1: Create GitHub Environments

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Environments**
3. Click **New environment** for each environment:
   - `dev`
   - `sandbox`
   - `staging`
   - `uat`
   - `prod`

### Environment Protection Rules

For production environment (`prod`):
- ✅ Required reviewers (add team members)
- ✅ Wait timer (optional, e.g., 5 minutes)
- ✅ Deployment branches (limit to `main` or `release/*`)

For staging environment (`staging`):
- ✅ Required reviewers (optional)
- ✅ Deployment branches (limit to `main`, `staging`, or `release/*`)

## Step 2: Set Up Repository Secrets

Navigate to **Settings** → **Secrets and variables** → **Actions** → **Repository secrets**

Add the following secrets:

### Security and Code Analysis

```bash
# SonarQube/SonarCloud token
SONAR_TOKEN=sqp_your_sonar_token_here

# Semgrep App token (if using Semgrep)
SEMGREP_APP_TOKEN=your_semgrep_token_here

# Snyk token (if using Snyk)
SNYK_TOKEN=your_snyk_token_here
```

### Container Registry

```bash
# Docker Hub credentials (if using Docker Hub)
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=dckr_pat_your_dockerhub_token
```

### General Configuration

```bash
# S3 bucket for storing artifacts (optional)
ARTIFACT_BUCKET=my-org-artifacts

# S3 bucket for Lambda deployments
LAMBDA_DEPLOY_BUCKET=my-lambda-deployments
```

## Step 3: Set Up Environment-Specific Secrets

For each environment, navigate to **Settings** → **Environments** → **[Environment Name]** → **Environment secrets**

### Dev Environment Secrets

```bash
AWS_ACCOUNT_ID=111111111111
AWS_REGION=us-east-1
ECR_REGISTRY=111111111111.dkr.ecr.us-east-1.amazonaws.com
STATE_BUCKET=org-terraform-state-dev
DYNAMODB_TABLE=org-terraform-locks-dev
KMS_KEY_ARN=arn:aws:kms:us-east-1:111111111111:key/your-dev-key-id
```

### Sandbox Environment Secrets

```bash
AWS_ACCOUNT_ID=444444444444
AWS_REGION=us-east-1
ECR_REGISTRY=444444444444.dkr.ecr.us-east-1.amazonaws.com
STATE_BUCKET=org-terraform-state-sandbox
DYNAMODB_TABLE=org-terraform-locks-sandbox
KMS_KEY_ARN=arn:aws:kms:us-east-1:444444444444:key/your-sandbox-key-id
```

### Staging Environment Secrets

```bash
AWS_ACCOUNT_ID=222222222222
AWS_REGION=us-east-1
ECR_REGISTRY=222222222222.dkr.ecr.us-east-1.amazonaws.com
STATE_BUCKET=org-terraform-state-staging
DYNAMODB_TABLE=org-terraform-locks-staging
KMS_KEY_ARN=arn:aws:kms:us-east-1:222222222222:key/your-staging-key-id
```

### UAT Environment Secrets

```bash
AWS_ACCOUNT_ID=555555555555
AWS_REGION=us-east-1
ECR_REGISTRY=555555555555.dkr.ecr.us-east-1.amazonaws.com
STATE_BUCKET=org-terraform-state-uat
DYNAMODB_TABLE=org-terraform-locks-uat
KMS_KEY_ARN=arn:aws:kms:us-east-1:555555555555:key/your-uat-key-id
```

### Production Environment Secrets

```bash
AWS_ACCOUNT_ID=333333333333
AWS_REGION=us-east-1
ECR_REGISTRY=333333333333.dkr.ecr.us-east-1.amazonaws.com
STATE_BUCKET=org-terraform-state-prod
DYNAMODB_TABLE=org-terraform-locks-prod
KMS_KEY_ARN=arn:aws:kms:us-east-1:333333333333:key/your-prod-key-id
```

## Step 4: Update Workflow Files

Update your GitHub Actions workflow files to use environments and secrets properly.

### Example: Terraform Workflow Updates

Replace hardcoded values in `.github/workflows/terraform-apply.yml`:

```yaml
name: Terraform Apply
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - sandbox
        - staging
        - uat
        - prod

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsOIDCRole
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.STATE_BUCKET }}" \
            -backend-config="key=infrastructure/terraform.tfstate" \
            -backend-config="region=${{ secrets.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.DYNAMODB_TABLE }}"
```

### Example: SBOM/SCA Workflow Updates

Update `.github/workflows/sbom-sca.yml`:

```yaml
name: SBOM and SCA
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  sbom-sca:
    runs-on: ubuntu-latest
    environment: dev  # Use dev for CI builds
    
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsOIDCRole
          aws-region: ${{ secrets.AWS_REGION }}
      
      # ... existing steps ...
      
      - name: Upload to S3
        if: secrets.ARTIFACT_BUCKET != ''
        run: |
          aws s3 cp artifacts/ s3://${{ secrets.ARTIFACT_BUCKET }}/${{ github.run_id }}/ --recursive
```

## Step 5: AWS OIDC Role Setup

Ensure your AWS OIDC roles are properly configured for each environment. See the [IAM Examples](../../github-actions/devsecops/iam-examples/README.md) for detailed setup instructions.

### Trust Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:papaert-cloud/Generic:environment:dev"
        }
      }
    }
  ]
}
```

## Step 6: Testing

### Test Repository Secrets

1. Trigger a workflow that uses repository secrets (e.g., SonarQube scan)
2. Check the workflow logs to ensure secrets are being resolved
3. Verify no secrets are exposed in logs

### Test Environment Secrets

1. Run a workflow against the `dev` environment
2. Verify AWS authentication works
3. Check that environment-specific resources are being used

### Test Environment Protection

1. Try to deploy to `prod` environment
2. Verify that approval is required (if configured)
3. Confirm deployment restrictions work

## Step 7: Validation Checklist

- [ ] All repository secrets are configured
- [ ] All environment secrets are configured for each environment
- [ ] Environment protection rules are set up for prod/staging
- [ ] Workflows updated to use secrets instead of hardcoded values
- [ ] AWS OIDC roles are configured with proper trust policies
- [ ] Test deployments work for each environment
- [ ] No secrets are exposed in workflow logs
- [ ] Environment isolation is working (dev doesn't affect prod)

## Troubleshooting

### Secret Not Found Error

```
Error: Secret SONAR_TOKEN not found
```

**Solution**: 
1. Check secret name spelling in workflow
2. Verify secret is created in correct scope (repository vs environment)
3. Ensure environment name matches in workflow

### AWS Authentication Failed

```
Error: Could not assume role with OIDC
```

**Solution**:
1. Verify `AWS_ACCOUNT_ID` secret is correct
2. Check OIDC provider is set up in AWS
3. Verify trust policy conditions match repository and environment
4. Ensure role has necessary permissions

### Environment Not Found

```
Error: Environment 'staging' not found
```

**Solution**:
1. Create the environment in repository settings
2. Verify environment name matches exactly in workflow
3. Check that environment is not restricted to specific branches

## Security Best Practices

1. **Use least privilege**: Only grant minimum required permissions
2. **Rotate secrets regularly**: Set up rotation schedules for long-lived tokens
3. **Monitor usage**: Review secret access logs regularly
4. **Use environment protection**: Require approvals for production deployments
5. **Audit access**: Regularly review who has access to secrets

## Next Steps

1. **Automate secret rotation**: Set up automated rotation for long-lived secrets
2. **Implement monitoring**: Set up alerts for secret usage anomalies
3. **Document procedures**: Create runbooks for secret management
4. **Train team**: Ensure team members understand secret management practices
