🛡️ DevSecOps Security Lab

✨ Motivation

Modern software supply chains demand end-to-end security. Vulnerabilities in third-party dependencies, secrets in version control, and opaque build environments can derail delivery and compliance.

This lab is my personal journey and portfolio project (with embedded explanation snippets) — a living demonstration of how to build secure, automated pipelines that generate Software Bills of Materials (SBOMs), scan dependencies, sign and verify container images, enforce runtime policies, and align with industry frameworks such as:

🏛️ Executive Order 14028 (SBOMs, supply chain integrity)

🛠️ NIST Secure Software Development Framework (SSDF)

🔒 Supply-chain Levels for Software Artifacts (SLSA)

🧩 CIS Benchmarks and compliance baselines

Each workflow is purpose-built: it explains how to run it, highlights the lessons behind it, and suggests ways to extend it. This lab serves both as lesson-learned to document my journey so-far and as a practical reference point to demonstrate applied DevSecOps practices that can be intergrated into SDLC environments. 

🧩 Project Overview

This project demonstrates end-to-end DevSecOps and AppSec practices in a reproducible environment:

Infrastructure-as-Code (IaC):
Provision AWS resources with Terraform/Terragrunt, supporting multiple environments (dev, test, prod, sandbox).


> SBOM Generation & Scanning:

Syft for CycloneDX/SPDX SBOMs

Trivy/Grype/Snyk for vulnerability scans

Pipelines block on Critical/High vulnerabilities


>  Secure Artifact Storage: >

Versioned S3 buckets with KMS encryption

Immutable SBOMs + scan reports for SLSA/SSDF audit integrity


> Cosign Image Signing & Verification: >

Sign container images and SBOMs with cosign

Enforce provenance in Kubernetes with Kyverno policies


> OIDC-based CI/CD: >

GitHub → AWS OIDC federation (no static keys)

Short-lived AWS STS tokens for least-privilege role sessions


> Centralized Security Hub Integration: >

Findings normalized into ASFF (AWS Security Finding Format)

Ingested into AWS Security Hub for centralized visibility


> Kubernetes Runtime Enforcement: >

Enforce SBOM annotations + cosign signatures

Reject workloads with unacceptable vulnerabilities


Compliance Crosswalk:
Documentation maps pipeline controls directly to EO 14028, NIST SSDF, SLSA, and CIS Benchmarks.


🗂️ Repository Structure
.
├── .github/workflows/   # 20+ GitHub Actions workflows for CI/CD & security
├── config/              # Lab configuration & metadata
├── dockers/             # Docker configurations & compose files
├── docs/                # Documentation, runbooks & compliance mapping
│   ├── scenario-5-security-workflows/  # End-to-end guides
│   ├── environments/    # Environment-specific docs
│   └── reference/       # Technical reference
├── github-actions/      # Reusable workflow templates
│   ├── devops/          # CI/CD workflows (build, deploy, infra)
│   ├── devsecops/       # Security workflows (SBOM, SCA, signing)
│   └── more-workflows/  # Additional pipeline patterns
├── Infra/               # Terraform/Terragrunt IaC
│   ├── environments/    # Dev/test/prod/sandbox IaC configs
│   └── solutions/       # Solution templates
├── solutions/           # Demo + scenario implementations
│   ├── demo-sbom-lab/   # SBOM generation + Security Hub integration
│   └── scenario-s003-000-secure-cicd-gha/
├── tools/               # PowerShell automation tools
└── scripts/             # Helper scripts for setup & ops


🚀 Getting Started
Prerequisites

Linux or WSL with Docker, Git, Node.js

AWS account (IAM, S3, ECR permissions)

GitHub repo with admin rights for OIDC setup

Tools: AWS CLI, Terraform, Syft, Grype, Cosign, Kyverno, Ansible

Bootstrap
git clone <your-repo-url>
cd lab
pwsh tools/ps/bootstrap.ps1 -Explain
pwsh tools/ps/detect-tools.ps1 -Explain

Infrastructure Setup
cd Infra/environments/dev
terraform init
terraform plan
terraform apply

GitHub Actions Setup

Configure OIDC trust relationship (see github-actions/devops/solution-02-infra-approval/)

Set repo secrets for AWS account/region

Push code → triggers demo-sbom-pipeline.yml

🏗️ Available Workflows

------ Core Security -------

demo-sbom-pipeline.yml → Full SBOM pipeline

sbom-sca.yml → Software Composition Analysis

sign-and-push.yml → Image signing (cosign)

scan-to-securityhub.yml → Security Hub integration

------ Infrastructure -------

terraform-plan.yml / terraform-apply.yml → IaC deployments

drift-detection.yml → Drift monitoring

------ Code Security -------

codeql-analysis.yml → GitHub CodeQL

semgrep-scan.yml → SAST scanning

dast-zap.yml → DAST with OWASP ZAP

sonar-scan.yml → Code quality

 ------- Ops & Maintenance ------ 

dependency-updates.yml → Automated updates

nightly-sbom-rescan.yml → Scheduled scans

canary-deploy.yml → Progressive deployment

📚 Learning Path

- Start with docs/scenario-5-security-workflows/00_overview.md

- Explore solutions under solutions/demo-sbom-lab/

- Deploy infrastructure with Infra/environments/

- Run workflows under .github/workflows/

- Map results to SLSA/SSDF/CIS compliance docs

⚡ Extending the Lab

+ Add new scanners (Bandit, Checkov)

+ Extend Terraform to Azure/GCP (multi-cloud)

+ Integrate OPA/Datree alongside Kyverno

+ Expand compliance docs (ISO 27001, PCI-DSS)

+ Automate ticketing via Security Hub → Jira/Slack

🔧 Tools & Technologies

Security: Syft, Grype, Trivy, Snyk, Cosign, Kyverno, Semgrep, CodeQL, OWASP ZAP
Infrastructure: Terraform, Ansible, AWS (S3, ECR, IAM, KMS, Security Hub, Config)
CI/CD: GitHub Actions (OIDC → AWS), GitAction, Jenkins (optional)
Containers: Docker, Kubernetes (kind, EKS pilot)
Languages: Python, PowerShell, Bash, HCL

🎯 Why This Matters (My Journey)

This repo is not just code — it reflects my journey into advanced Application Security and Cloud Security Engineering:

Started with system administration (Windows/Linux/Active Directory).

Introduced AWS basics and automation.

Advanced into DevSecOps pipelines, IaC security, SBOM tooling.

Today: building federal-grade, compliance-ready pipelines aligned with EO 14028 and NIST SSDF.

📜 License

MIT License — Feel free to use and adapt for learning, research, or professional development.
