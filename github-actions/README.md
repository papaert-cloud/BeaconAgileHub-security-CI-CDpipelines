# GitHub Actions DevOps & DevSecOps Solutions

## Architecture Overview

This directory contains two comprehensive pipeline solutions:

### 1. DevOps Pipeline (`devops/`)
- **Focus**: Speed, reliability, deployment efficiency
- **Key Features**: Automated testing, infrastructure provisioning, blue/green deployments
- **Tools**: Terraform, Docker, AWS services, performance monitoring

### 2. DevSecOps Pipeline (`devsecops/`)
- **Focus**: Security-first approach with shift-left principles
- **Key Features**: SBOM generation, vulnerability scanning, supply chain security
- **Tools**: Syft, Grype, Snyk, Cosign, Kyverno, Security Hub integration

## Directory Structure

```
github-actions/
├── devops/
│   ├── workflows/
│   ├── scripts/
│   ├── terraform/
│   └── docs/
├── devsecops/
│   ├── workflows/
│   ├── scripts/
│   ├── security-policies/
│   ├── compliance/
│   └── docs/
└── shared/
    ├── scripts/
    └── configs/
```

## Prerequisites

### Required Tools
- AWS CLI v2+
- Terraform >= 1.5
- Docker >= 20.10
- kubectl >= 1.25
- Go >= 1.19 (for custom tooling)

### AWS Services Setup
- IAM roles with OIDC provider
- S3 buckets for artifacts
- ECR repositories
- Security Hub enabled
- KMS keys for signing

## Quick Start

1. **Setup AWS OIDC Provider**:
   ```bash
   cd terraform/oidc-setup
   terraform init && terraform apply
   ```

2. **Configure Repository Secrets**:
   - `AWS_ACCOUNT_ID`
   - `AWS_REGION`
   - `ECR_REPOSITORY`

3. **Choose Your Pipeline**:
   - DevOps: Copy workflows from `devops/workflows/`
   - DevSecOps: Copy workflows from `devsecops/workflows/`

## Security Considerations

- All pipelines use OIDC authentication (no static keys)
- Least privilege IAM policies
- Encrypted artifact storage
- Signed container images
- Vulnerability gates prevent insecure deployments

## Compliance Mapping

- **NIST SSDF**: Supply chain security practices
- **SLSA**: Build integrity and provenance
- **CIS Benchmarks**: Infrastructure hardening
- **OWASP**: Application security best practices