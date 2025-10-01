
# scenario-s003-000-secure-cicd-gha — Secure CI/CD with GitHub Actions (GHA)

This folder contains an example, high-impact scaffold to deploy an automated remediation Lambda and a CloudFormation StackSet that enforces guardrails across multiple AWS accounts/OU. The workflow uses Terragrunt -> Terraform to provision the StackSet and related IAM, and a CloudFormation template for the StackSet-managed resources (Lambda + roles).

Important security note: Do NOT commit AWS credentials, private keys, or sensitive material to this repository. If you provided credentials out-of-band, rotate them immediately. This repo contains scaffolds and placeholders only.

Contents

- `terraform/`: Terraform module for deploying a CloudFormation StackSet and supporting IAM resources.
- `cf/stackset.yaml`: CloudFormation template skeleton for StackSet-managed resources (Lambda, roles). Fill the `Code` S3 location before deploying.
- `lambda/remediate.py`: Example Lambda auto-remediation handler (stub).
- `iam/stackset-execution-policy.json`: Example IAM policy for StackSet execution.
- `terragrunt.hcl`: Sample Terragrunt wrapper for the Terraform module.

High-level deployment flow

1. Build the Lambda deployment package (zip) and upload to a secure S3 bucket.
2. Populate the Terraform/Terragrunt variables with the S3 bucket/key, target OU/Account list and assumed roles.
3. Run `terragrunt init && terragrunt apply` (or `terragrunt apply-all`) from the environment folder to create the StackSet.
4. Create StackSet instances per-account/region (provider-specific) using the AWS CLI or Console.
5. Confirm StackSet instances are created in target accounts and monitor Lambda logs for remediation activity.

What I provide here

- A complete example Terraform module that creates an `aws_cloudformation_stack_set` and an execution role.
- A CloudFormation template skeleton (`cf/stackset.yaml`) that defines an IAM Role and a Lambda function (Code S3 placeholders).
- A small Python Lambda stub which you can extend to implement remediation logic (security group fixes, S3 public-block enforcement, etc.).
- Terragrunt example and usage notes.

Next steps (recommended)

- Review and customize the Lambda logic to the specific high-impact scenario you care about (ex: revoke public access, remove wide-open security groups, auto-rotate credentials detection).
- Implement CI step to build the Lambda zip and upload to S3 as part of your GitHub Actions pipeline.
- Use a dedicated deployment role with least privilege for Terragrunt/Terraform runs and enable MFA on user accounts.

Deployment example (detailed)

1) Build the Lambda package (from repo root):

```bash
python -m pip install -r Infra/solutions/scenario-s003-000-secure-cicd-gha/lambda/requirements.txt -t /tmp/lambda
cd /tmp/lambda
zip -r9 /tmp/remediate.zip .
```

2) Upload the zip to a secure S3 bucket (example):

```bash
aws s3 cp /tmp/remediate.zip s3://my-deployment-bucket/remediate/remediate.zip --region us-east-1
```

3) Update `terragrunt.hcl` inputs to set `lambda_code_bucket` and `target_account_ids`, then:

```bash
cd Infra/solutions/scenario-s003-000-secure-cicd-gha
terragrunt init
terragrunt apply
```

4) Create StackSet instances using AWS CLI (example):

```bash
aws cloudformation create-stack-instances \
	--stack-set-name $(terraform output -raw stackset_name) \
	--accounts 111111111111 222222222222 \
	--regions us-east-1 \
	--region us-east-1
```

