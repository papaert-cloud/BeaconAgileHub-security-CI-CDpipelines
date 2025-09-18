# Testing Framework Implementation Guide

## Overview

Comprehensive testing framework implementing industry-standard practices for Infrastructure as Code validation, security compliance, and cost optimization.

## Testing Pyramid

```
    /\     E2E Tests (Integration)
   /  \    
  /____\   Security & Compliance Tests  
 /      \  
/________\  Unit Tests (Terratest)
```

## Prerequisites

### Required Tools

```bash
# Go for Terratest
go version  # >= 1.21

# Python for security tests
python3 --version  # >= 3.11
pip install pytest boto3 moto cfn-lint

# Terraform
terraform --version  # >= 1.6.0

# AWS CLI
aws --version  # >= 2.0

# Optional: Infracost for cost estimation
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
```

### Environment Setup

```bash
# AWS Credentials (for integration tests)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Infracost API Key (optional)
export INFRACOST_API_KEY="your-infracost-key"
```

## Test Categories

### 1. Unit Tests (Terratest)

**Location**: `tests/unit/`
**Purpose**: Fast feedback on Terraform modules without deployment

```bash
cd tests
go mod tidy
go test -v ./unit/... -timeout 10m
```

**Features**:
- Plan-only validation
- Resource configuration verification
- Input/output validation
- No AWS resources created

### 2. Integration Tests

**Location**: `tests/integration/`
**Purpose**: Full deployment testing in sandbox environments

```bash
# Requires AWS credentials
go test -v ./integration/... -timeout 30m
```

**Features**:
- Complete infrastructure deployment
- Resource validation
- Cross-module integration
- Automatic cleanup

### 3. Security Tests

**Location**: `tests/security/`
**Purpose**: Security compliance validation

```bash
cd tests
python -m pytest security/ -v
```

**Validates**:
- VPC Flow Logs enabled
- S3 encryption configuration
- Security group rules
- Network ACL configuration
- KMS key policies

### 4. CloudFormation Validation

**Purpose**: Template syntax and security validation

```bash
# Lint templates
cfn-lint cloudformation/templates/*.yaml

# Security checks
cfn-lint cloudformation/templates/*.yaml --include-checks I
```

## CI/CD Integration

### GitHub Actions Workflow

The validation pipeline runs on:
- Pull requests affecting infrastructure
- Pushes to main/develop branches

**Stages**:
1. **Terraform Validation**: Format, validate, plan
2. **CloudFormation Validation**: Lint, security scan
3. **Security Scanning**: Checkov SAST analysis
4. **Cost Estimation**: Infracost analysis
5. **Unit Testing**: Terratest execution
6. **Security Testing**: Compliance validation

### Workflow Configuration

```yaml
# .github/workflows/infrastructure-validation.yml
name: Infrastructure Validation
on:
  pull_request:
    paths: ['terraform/**', 'cloudformation/**']
```

## Test Execution

### Local Development

```bash
# Run all unit tests
make test-unit

# Run security tests
make test-security

# Run integration tests (requires AWS)
make test-integration

# Validate CloudFormation
make validate-cfn
```

### Makefile Commands

```bash
# Create Makefile for convenience
cat > Makefile << 'EOF'
.PHONY: test-unit test-integration test-security validate-cfn

test-unit:
	cd tests && go test -v ./unit/... -timeout 10m

test-integration:
	cd tests && go test -v ./integration/... -timeout 30m

test-security:
	cd tests && python -m pytest security/ -v

validate-cfn:
	cfn-lint cloudformation/templates/*.yaml

test-all: test-unit test-security validate-cfn
EOF
```

## Cost Optimization

### Infracost Integration

```bash
# Generate cost breakdown
infracost breakdown --path=terraform/ --format=table

# Compare costs between branches
infracost diff --path=terraform/ --compare-to=main
```

### Cost Controls

- Sandbox environment limits
- Resource tagging for cost allocation
- Automated cost alerts
- Regular cost reviews

## Troubleshooting

### Common Issues

**Go Module Issues**:
```bash
cd tests
go mod tidy
go clean -modcache
```

**AWS Permissions**:
```bash
# Verify credentials
aws sts get-caller-identity

# Test permissions
aws ec2 describe-vpcs --region us-west-2
```

**Terraform State**:
```bash
# Clean state for tests
rm -rf tests/**/.terraform*
rm -rf tests/**/terraform.tfstate*
```

### Test Isolation

- Each test uses unique resource names
- Automatic cleanup with defer statements
- Separate AWS accounts for environments
- Resource tagging for identification

## Best Practices

### Test Design

1. **Fast Feedback**: Unit tests complete in < 2 minutes
2. **Isolation**: Tests don't depend on each other
3. **Cleanup**: Always clean up resources
4. **Parallel**: Run tests in parallel when possible
5. **Deterministic**: Tests produce consistent results

### Security Testing

1. **Shift-Left**: Security validation in early stages
2. **Comprehensive**: Cover all security domains
3. **Automated**: No manual security checks
4. **Compliance**: Map to security frameworks
5. **Continuous**: Run on every change

### Cost Management

1. **Estimation**: Cost impact before deployment
2. **Monitoring**: Track cost trends
3. **Optimization**: Regular cost reviews
4. **Alerts**: Automated cost threshold alerts
5. **Governance**: Cost approval workflows

## Metrics & Reporting

### Test Metrics

- Test execution time
- Test coverage percentage
- Failure rates by category
- Security compliance score

### Cost Metrics

- Infrastructure cost per environment
- Cost per feature/service
- Cost optimization opportunities
- Budget variance tracking

## Integration with Development Workflow

### Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Setup hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### IDE Integration

- VS Code Terraform extension
- Go test integration
- Python test discovery
- CloudFormation validation

This testing framework ensures high-quality, secure, and cost-effective infrastructure deployments while maintaining rapid development velocity.