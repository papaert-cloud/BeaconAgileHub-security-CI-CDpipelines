#!/bin/bash
# Environment Setup Script for DevSecOps Pipeline

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="sbom-security-pipeline"
AWS_REGION="us-east-1"
ENVIRONMENTS=("dev" "staging" "production")

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    local tools=("aws" "terraform" "kubectl" "docker" "cosign" "syft" "grype")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is not installed. Please install it first."
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Run 'aws configure' first."
    fi
    
    log "Prerequisites check passed ✓"
}

setup_terraform_backend() {
    log "Setting up Terraform backend..."
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    for env in "${ENVIRONMENTS[@]}"; do
        local bucket_name="terraform-state-${env}-${account_id}"
        local table_name="terraform-locks-${env}"
        
        # Create S3 bucket for state
        if ! aws s3 ls "s3://${bucket_name}" &> /dev/null; then
            aws s3 mb "s3://${bucket_name}" --region "$AWS_REGION"
            aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled
            aws s3api put-bucket-encryption --bucket "$bucket_name" --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'
            log "Created S3 bucket: $bucket_name"
        fi
        
        # Create DynamoDB table for locking
        if ! aws dynamodb describe-table --table-name "$table_name" &> /dev/null; then
            aws dynamodb create-table \
                --table-name "$table_name" \
                --attribute-definitions AttributeName=LockID,AttributeType=S \
                --key-schema AttributeName=LockID,KeyType=HASH \
                --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
                --region "$AWS_REGION"
            log "Created DynamoDB table: $table_name"
        fi
    done
}

setup_github_oidc() {
    log "Setting up GitHub OIDC..."
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local repo_name=$(git remote get-url origin | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/')
    
    # Create OIDC provider
    local oidc_arn="arn:aws:iam::${account_id}:oidc-provider/token.actions.githubusercontent.com"
    if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$oidc_arn" &> /dev/null; then
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --client-id-list sts.amazonaws.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
        log "Created GitHub OIDC provider"
    fi
    
    # Create IAM role for GitHub Actions
    local role_name="GitHubActionsRole"
    local trust_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${oidc_arn}"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${repo_name}:*"
                }
            }
        }
    ]
}
EOF
)
    
    if ! aws iam get-role --role-name "$role_name" &> /dev/null; then
        aws iam create-role --role-name "$role_name" --assume-role-policy-document "$trust_policy"
        aws iam attach-role-policy --role-name "$role_name" --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
        log "Created GitHub Actions IAM role"
    fi
    
    log "GitHub OIDC setup complete. Add this to your repository secrets:"
    echo "AWS_ROLE_ARN: arn:aws:iam::${account_id}:role/${role_name}"
}

setup_security_tools() {
    log "Setting up security tools..."
    
    # Install additional tools if needed
    if ! command -v checkov &> /dev/null; then
        pip3 install checkov
        log "Installed Checkov"
    fi
    
    if ! command -v kustomize &> /dev/null; then
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
        log "Installed Kustomize"
    fi
    
    # Setup pre-commit hooks
    if [ -f .pre-commit-config.yaml ]; then
        pip3 install pre-commit
        pre-commit install
        log "Installed pre-commit hooks"
    fi
}

create_environment_configs() {
    log "Creating environment configurations..."
    
    for env in "${ENVIRONMENTS[@]}"; do
        local env_dir="terragrunt/environments/${env}"
        mkdir -p "$env_dir"
        
        # Create environment-specific configuration
        cat > "${env_dir}/env.hcl" <<EOF
locals {
  environment = "${env}"
  
  # Environment-specific variables
  vpc_cidr = "${env}" == "production" ? "10.0.0.0/16" : "10.${env:0:1}0.0.0/16"
  
  # Security settings
  enable_deletion_protection = "${env}" == "production" ? true : false
  backup_retention_days = "${env}" == "production" ? 30 : 7
  
  # Monitoring settings
  log_retention_days = "${env}" == "production" ? 365 : 30
  enable_detailed_monitoring = "${env}" == "production" ? true : false
}
EOF
        
        # Create terragrunt configuration for each module
        local modules=("network-security" "endpoint-security" "application-security" "database-security" "threat-intelligence")
        for module in "${modules[@]}"; do
            local module_dir="${env_dir}/${module}"
            mkdir -p "$module_dir"
            
            cat > "${module_dir}/terragrunt.hcl" <<EOF
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "../../../../terraform/modules/${module}"
}

inputs = {
  # Module-specific inputs will be added here
}
EOF
        done
        
        log "Created configuration for $env environment"
    done
}

setup_kubernetes_configs() {
    log "Setting up Kubernetes configurations..."
    
    # Create base kustomization
    cat > kubernetes/base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
- ingress.yaml

commonLabels:
  app: ${PROJECT_NAME}
  version: v1.0.0
EOF
    
    # Create environment overlays
    for env in "${ENVIRONMENTS[@]}"; do
        local overlay_dir="kubernetes/overlays/${env}"
        mkdir -p "$overlay_dir"
        
        cat > "${overlay_dir}/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${PROJECT_NAME}-${env}

resources:
- ../../base

patchesStrategicMerge:
- deployment-patch.yaml

commonLabels:
  environment: ${env}

replicas:
- name: ${PROJECT_NAME}
  count: $([[ "$env" == "production" ]] && echo "3" || echo "1")
EOF
        
        # Create deployment patch
        cat > "${overlay_dir}/deployment-patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${PROJECT_NAME}
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: ENVIRONMENT
          value: "${env}"
        resources:
          requests:
            memory: "$([[ "$env" == "production" ]] && echo "512Mi" || echo "256Mi")"
            cpu: "$([[ "$env" == "production" ]] && echo "500m" || echo "250m")"
          limits:
            memory: "$([[ "$env" == "production" ]] && echo "1Gi" || echo "512Mi")"
            cpu: "$([[ "$env" == "production" ]] && echo "1000m" || echo "500m")"
EOF
        
        log "Created Kubernetes overlay for $env"
    done
}

generate_documentation() {
    log "Generating additional documentation..."
    
    # Create .gitignore
    cat > .gitignore <<EOF
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Security
*.pem
*.key
secrets/
EOF
    
    # Create pre-commit configuration
    cat > .pre-commit-config.yaml <<EOF
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: detect-private-key
  
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
  
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
  
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
EOF
    
    log "Generated project documentation"
}

main() {
    log "Starting DevSecOps pipeline bootstrap..."
    
    check_prerequisites
    setup_terraform_backend
    setup_github_oidc
    setup_security_tools
    create_environment_configs
    setup_kubernetes_configs
    generate_documentation
    
    log "Bootstrap complete! 🎉"
    log ""
    log "Next steps:"
    log "1. Add AWS_ROLE_ARN to your GitHub repository secrets"
    log "2. Add SNYK_TOKEN to your GitHub repository secrets"
    log "3. Run 'terragrunt plan' in each environment directory"
    log "4. Commit and push your changes to trigger the CI/CD pipeline"
}

main "$@"