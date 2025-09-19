# Repository Structure Guide

## Overview
This guide explains the organization and intention behind the Enterprise DevSecOps Pipeline with ICS Security Integration repository structure.

## Repository Architecture

### Core Principles
- **Separation of Concerns**: Clear boundaries between CI, CD, and Infrastructure
- **Reusability**: Modular workflows and Terraform modules
- **Security-First**: ICS-grade security controls at every layer
- **Environment Isolation**: Dev/Staging/Production separation
- **Compliance-Ready**: Built-in framework alignment

## Directory Structure

### `.github/workflows/`
**Purpose**: GitHub Actions workflow orchestration

```
.github/workflows/
├── _reusable/              # Core reusable workflow components
│   ├── security-gates.yml  # SAST/DAST/SCA/SBOM validation
│   ├── infrastructure.yml  # Terraform/Terragrunt deployment
│   ├── compliance.yml      # ICS/SLSA/CIS validation
│   └── runtime-protection.yml # Kyverno/Falco monitoring
├── ci-pipeline.yml         # Development integration workflow
├── cd-pipeline.yml         # Deployment orchestration workflow
└── ics-security-validation.yml # Industrial-grade security auditing
```

**Key Features**:
- Workflow chaining for modular execution
- Environment-aware deployments
- Security gates at every stage
- OIDC authentication (no static keys)

### `terraform/`
**Purpose**: Infrastructure as Code with security modules

```
terraform/
├── modules/                # Reusable infrastructure components
│   ├── network-security/   # VPC, segmentation, monitoring
│   ├── endpoint-security/  # EKS hardening, encryption
│   ├── application-security/ # ALB, WAF, Shield
│   ├── database-security/  # RDS encryption, access control
│   └── threat-intelligence/ # GuardDuty, Security Hub
└── environments/           # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── production/
```

**Security Focus**:
- ICS-grade network segmentation
- Defense-in-depth architecture
- Encryption at rest and in transit
- Comprehensive monitoring

### `terragrunt/`
**Purpose**: DRY configuration management

```
terragrunt/
├── terragrunt.hcl         # Global configuration
└── environments/          # Environment hierarchy
    ├── dev/
    ├── staging/
    └── production/
```

**Benefits**:
- Eliminates code duplication
- Environment-specific variables
- Consistent backend configuration
- Simplified multi-environment management

### `kubernetes/`
**Purpose**: Container orchestration with security policies

```
kubernetes/
├── base/                  # Base Kubernetes manifests
├── overlays/              # Environment-specific customizations
│   ├── dev/
│   ├── staging/
│   └── production/
└── policies/              # Kyverno security policies
```

**Security Controls**:
- Pod Security Standards enforcement
- Network policies for micro-segmentation
- Image signature verification
- SBOM attestation requirements

### `app/`
**Purpose**: Secure demo application

```
app/
├── app.py                 # Flask application with security endpoints
├── Dockerfile             # Multi-stage hardened container
└── requirements.txt       # Python dependencies
```

**Security Features**:
- Non-root container execution
- Security headers implementation
- ICS status endpoints
- AWS Security Hub integration

### `docs/`
**Purpose**: Comprehensive documentation

```
docs/
├── compliance-mapping.md   # Framework alignment documentation
├── threat-model.md        # Industrial-grade threat analysis
├── security-runbooks.md   # Incident response procedures
└── repository-guide.md    # This guide
```

**Coverage**:
- SLSA/SSDF/CIS/ICS compliance mapping
- Threat modeling for ICS environments
- Step-by-step incident response
- Architecture explanations

### `scripts/`
**Purpose**: Automation utilities

```
scripts/
├── bootstrap.sh           # Environment setup and AWS OIDC
├── security-validation.sh # SBOM generation and vulnerability scanning
└── compliance-check.sh    # Framework compliance validation
```

**Capabilities**:
- Automated environment bootstrapping
- Comprehensive security testing
- Multi-framework compliance checking
- Report generation and analysis

## Workflow Orchestration

### CI Pipeline Flow
1. **Trigger**: Code push or PR
2. **Environment Detection**: Determine target environment
3. **Security Gates**: SAST/DAST/SCA/SBOM validation
4. **Build & Test**: Container build with signing
5. **ICS Validation**: Industrial security checks

### CD Pipeline Flow
1. **Trigger**: Successful CI completion
2. **Infrastructure Deployment**: Terragrunt-managed provisioning
3. **Runtime Protection**: Kyverno/Falco deployment
4. **Compliance Validation**: Post-deployment checks

### Security Integration Points
- **Pre-commit**: Secret detection, linting
- **Build**: SBOM generation, vulnerability scanning
- **Deploy**: Policy validation, signature verification
- **Runtime**: Continuous monitoring, threat detection

## Environment Strategy

### Development
- **Purpose**: Rapid iteration and testing
- **Security**: Relaxed policies, full logging
- **Resources**: Minimal footprint, cost-optimized

### Staging
- **Purpose**: Production-like validation
- **Security**: Full security controls, compliance testing
- **Resources**: Production-equivalent configuration

### Production
- **Purpose**: Live workloads
- **Security**: Maximum security, manual approvals
- **Resources**: High availability, disaster recovery

## ICS Security Implementation

### Network Security
- **Segmentation**: DMZ/Application/Data zones
- **Monitoring**: VPC Flow Logs, real-time analysis
- **Protection**: NACLs, Security Groups, WAF

### Endpoint Security
- **Hardening**: CIS benchmarks, minimal attack surface
- **Encryption**: EBS/EFS encryption, KMS management
- **Monitoring**: Runtime security with Falco

### Application Security
- **Testing**: SAST/DAST integration, dependency scanning
- **Supply Chain**: SBOM generation, signature verification
- **Runtime**: Admission controllers, policy enforcement

### Database Security
- **Encryption**: At-rest and in-transit protection
- **Access**: Fine-grained IAM, database roles
- **Monitoring**: Audit logging, anomaly detection

## Compliance Framework Alignment

### SLSA (Supply-chain Levels)
- **Level 1**: Build process documentation ✓
- **Level 2**: Tamper-resistant build service ✓
- **Level 3**: Non-falsifiable provenance ✓
- **Level 4**: Hermetic builds (in progress)

### SSDF (Secure Software Development)
- **Prepare Organization**: Training, standards ✓
- **Protect Software**: Threat modeling, secure coding ✓
- **Produce Secured Software**: Testing, review ✓
- **Respond to Vulnerabilities**: Monitoring, remediation ✓

### CIS Benchmarks
- **Docker**: Non-root users, trusted images ✓
- **Kubernetes**: Security contexts, network policies ✓
- **Cloud**: Resource hardening, access control ✓

### ICS Standards
- **NERC CIP**: Electronic security perimeter ✓
- **IEC 62443**: Security Level 2 implementation ✓
- **NIST 800-82**: Industrial control systems security ✓

## Getting Started

### Prerequisites
```bash
# Required tools
aws --version          # AWS CLI v2
terraform --version    # Terraform >= 1.6.0
kubectl version        # Kubernetes CLI
docker --version       # Docker Engine
syft --version         # SBOM generation
grype --version        # Vulnerability scanning
```

### Quick Start
```bash
# 1. Bootstrap environment
./scripts/bootstrap.sh

# 2. Run security validation
./scripts/security-validation.sh

# 3. Check compliance
./scripts/compliance-check.sh

# 4. Deploy infrastructure
cd terragrunt/environments/dev
terragrunt apply
```

### Repository Customization

#### Adding New Security Controls
1. Create Terraform module in `terraform/modules/`
2. Add Kyverno policy in `kubernetes/policies/`
3. Update compliance mapping in `docs/compliance-mapping.md`
4. Add validation to `scripts/security-validation.sh`

#### Environment Configuration
1. Update `terragrunt/environments/<env>/env.hcl`
2. Modify Kubernetes overlays in `kubernetes/overlays/<env>/`
3. Adjust workflow triggers in `.github/workflows/`

#### Compliance Framework Addition
1. Create validation logic in `scripts/compliance-check.sh`
2. Document requirements in `docs/compliance-mapping.md`
3. Add framework-specific policies

## Best Practices

### Security
- Use OIDC instead of static credentials
- Implement least privilege access
- Enable comprehensive logging
- Regular security assessments

### Operations
- Environment parity maintenance
- Automated testing at all levels
- Infrastructure as Code principles
- Disaster recovery planning

### Compliance
- Regular framework updates
- Continuous compliance monitoring
- Evidence collection automation
- Audit trail maintenance

## Support and Maintenance

### Regular Tasks
- Security tool updates
- Compliance framework reviews
- Threat model updates
- Incident response testing

### Monitoring
- Security metrics dashboards
- Compliance score tracking
- Vulnerability trend analysis
- Performance impact assessment

This repository structure provides a production-ready foundation for enterprise DevSecOps with industrial-grade security controls, comprehensive compliance coverage, and operational excellence.