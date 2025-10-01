# Deployment guide — secure-cicd-gha

Prerequisites

- AWS CLI configured with a deployment-capable principal or an assume-role ARN for cross-account operations.
- A private S3 bucket to host Lambda deployment zips (encrypted at rest).
- Terragrunt and Terraform installed locally, or use CI to run them.
- GitHub repository secrets configured: `LAMBDA_DEPLOY_BUCKET`, `DEPLOY_ROLE_ARN` (role for CI to assume).

High level steps

1. Build the Lambda package
   - `make -C Infra/solutions/scenario-s003-000-secure-cicd-gha build`

2. Upload the Lambda zip to your private S3 bucket
   - `make -C Infra/solutions/scenario-s003-000-secure-cicd-gha upload S3_BUCKET=my-bucket`

3. Configure Terragrunt inputs
   - Edit `Infra/solutions/scenario-s003-000-secure-cicd-gha/terragrunt.hcl` (or per-env files in `Infra/environments/<env>/`) and set `lambda_code_bucket`, `target_account_ids`, and `administration_role_arn`.

4. Run Terragrunt to create the StackSet
   - `cd Infra/solutions/scenario-s003-000-secure-cicd-gha`
   - `terragrunt init`
   - `terragrunt apply`

5. Create StackSet instances in target accounts/regions
   - Example using AWS CLI:

```bash
aws cloudformation create-stack-instances \
  --stack-set-name <stackset-name> \
  --accounts 111111111111 222222222222 \
  --regions us-east-1 \
  --region us-east-1
```

6. Verify
   - Check CloudFormation StackSet status in the console.
   - Verify Lambda exists in target account(s) and review CloudWatch logs.

CI integration hints

- The GitHub Actions workflow `.github/workflows/secure-cicd-gha-deploy.yml` demonstrates build/upload and a Terragrunt `plan`. Configure GitHub Secrets to allow the workflow to upload the Lambda and assume a deploy role for Terragrunt runs.
- Implement protected branch workflows and require approvals for `apply` runs. In CI, prefer `plan` on PRs and `apply` only from protected branches with manual approval.

Security & operational notes

- Rotate any exposed credentials immediately and never store them in the repo.
- Use least-privilege roles for deployments and enable MFA.
- Use S3 bucket encryption and block public access.
