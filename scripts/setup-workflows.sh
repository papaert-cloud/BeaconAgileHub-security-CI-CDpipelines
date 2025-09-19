#!/bin/bash
set -e

echo "🚀 Setting up Enterprise DevSecOps Workflows"
echo "============================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is required but not installed"
    echo "   Install from: https://cli.github.com/"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Set up repository secrets (you'll need to provide actual values)
echo ""
echo "🔐 Setting up repository secrets..."
echo "   You'll need to provide actual values for these secrets:"

# AWS Role ARN for OIDC
read -p "Enter AWS Role ARN for GitHub OIDC (or press Enter to skip): " AWS_ROLE_ARN
if [ ! -z "$AWS_ROLE_ARN" ]; then
    gh secret set AWS_ROLE_ARN --body "$AWS_ROLE_ARN"
    echo "✅ AWS_ROLE_ARN set"
fi

# Snyk Token
read -p "Enter Snyk Token (or press Enter to skip): " SNYK_TOKEN
if [ ! -z "$SNYK_TOKEN" ]; then
    gh secret set SNYK_TOKEN --body "$SNYK_TOKEN"
    echo "✅ SNYK_TOKEN set"
fi

# SonarQube Token
read -p "Enter SonarQube Token (or press Enter to skip): " SONAR_TOKEN
if [ ! -z "$SONAR_TOKEN" ]; then
    gh secret set SONAR_TOKEN --body "$SONAR_TOKEN"
    echo "✅ SONAR_TOKEN set"
fi

echo ""
echo "🎯 Available Workflows:"
echo "======================"
echo ""
echo "📋 MAIN WORKFLOWS (triggered automatically):"
echo "  • ci-pipeline.yml                 - CI/CD pipeline (on push/PR)"
echo "  • cd-pipeline.yml                 - Deployment pipeline (after CI)"
echo "  • enterprise-orchestrator.yml     - Master orchestration (manual/scheduled)"
echo ""
echo "🔧 REUSABLE WORKFLOWS (called by main workflows):"
echo "  • security-gates.yml              - Security scanning"
echo "  • cd-deployment.yml               - Application deployment"
echo "  • comprehensive-security.yml      - Full security orchestration"
echo "  • infrastructure-orchestrator.yml - Infrastructure management"
echo "  • advanced-deployment.yml         - Advanced deployment strategies"
echo "  • comprehensive-testing.yml       - Multi-layer testing"
echo "  • enterprise-monitoring.yml       - Monitoring setup"
echo "  • cost-orchestrator.yml           - Cost optimization"
echo "  • compliance-orchestrator.yml     - Compliance validation"
echo "  • dr-orchestrator.yml             - Disaster recovery"
echo ""
echo "🧪 TESTING WORKFLOWS:"
echo "  • ics-security-validation.yml     - ICS security validation"
echo "  • infrastructure-validation.yml   - Infrastructure validation"
echo ""

echo "🚀 How to test your workflows:"
echo "=============================="
echo ""
echo "1. AUTOMATIC TRIGGERS:"
echo "   git add ."
echo "   git commit -m 'feat: trigger CI pipeline'"
echo "   git push origin main    # Triggers CI → CD → Production deployment"
echo ""
echo "2. MANUAL TRIGGERS:"
echo "   gh workflow run 'Enterprise DevSecOps Master Orchestrator'"
echo "   gh workflow run 'Disaster Recovery Orchestrator'"
echo ""
echo "3. VIEW WORKFLOW RUNS:"
echo "   gh run list"
echo "   gh run view <run-id>"
echo ""
echo "4. MONITOR IN BROWSER:"
echo "   gh browse --settings # Go to Actions tab"
echo ""

echo "✅ Setup complete!"
echo ""
echo "🎯 NEXT STEPS:"
echo "1. Commit and push these changes to trigger the CI pipeline"
echo "2. Set up AWS OIDC if you haven't already"
echo "3. Configure any missing secrets in GitHub repository settings"
echo "4. Test the master orchestrator with: gh workflow run 'Enterprise DevSecOps Master Orchestrator'"