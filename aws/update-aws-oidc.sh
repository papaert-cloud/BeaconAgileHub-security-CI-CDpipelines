#!/bin/bash
# 🔐 AWS OIDC TRUST POLICY UPDATE SCRIPT
# Updates AWS IAM trust policy for repository name change

set -euo pipefail

echo "🔐 AWS OIDC TRUST POLICY UPDATE"
echo "================================"
echo ""

# Configuration
ROLE_NAME="GitHubActionsRole"
POLICY_FILE="aws/oidc-trust-policy-update.json"
NEW_REPO="papaert-cloud/peter-security-CI-CDpipelines"
AWS_ACCOUNT="005965605891"

# Validate AWS CLI access
echo "🔍 Validating AWS access..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ ERROR: No AWS credentials available"
    echo "💡 SOLUTION: Configure AWS credentials"
    echo "  aws configure"
    echo "  # OR"
    echo "  export AWS_ACCESS_KEY_ID=..."
    echo "  export AWS_SECRET_ACCESS_KEY=..."
    exit 1
fi

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT" ]; then
    echo "❌ ERROR: Wrong AWS account"
    echo "  Expected: $AWS_ACCOUNT"
    echo "  Current: $CURRENT_ACCOUNT"
    exit 1
fi

echo "✅ AWS credentials verified for account: $CURRENT_ACCOUNT"
echo ""

# Check if role exists
echo "🔍 Checking IAM role: $ROLE_NAME"
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "❌ ERROR: Role $ROLE_NAME does not exist"
    echo "💡 SOLUTION: Create the role first or check role name"
    exit 1
fi

echo "✅ Role $ROLE_NAME exists"
echo ""

# Backup current trust policy
echo "💾 Backing up current trust policy..."
BACKUP_FILE="aws/trust-policy-backup-$(date +%Y%m%d-%H%M%S).json"
aws iam get-role --role-name "$ROLE_NAME" --query 'Role.AssumeRolePolicyDocument' --output json > "$BACKUP_FILE"
echo "✅ Current trust policy backed up to: $BACKUP_FILE"
echo ""

# Validate new trust policy file
echo "🔍 Validating new trust policy file: $POLICY_FILE"
if [ ! -f "$POLICY_FILE" ]; then
    echo "❌ ERROR: Policy file $POLICY_FILE does not exist"
    exit 1
fi

# Validate JSON syntax
if ! jq . "$POLICY_FILE" >/dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON in policy file $POLICY_FILE"
    exit 1
fi

echo "✅ Trust policy file validated"
echo ""

# Show what will be updated
echo "📝 POLICY UPDATE PREVIEW:"
echo "  Role: $ROLE_NAME"
echo "  New Repository: $NEW_REPO"
echo "  Policy File: $POLICY_FILE"
echo ""

# Display the new policy
echo "📋 NEW TRUST POLICY CONTENT:"
echo "---"
jq . "$POLICY_FILE"
echo "---"
echo ""

# Apply the updated trust policy
echo "🚀 Applying updated trust policy..."
aws iam update-assume-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-document file://"$POLICY_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Trust policy updated successfully!"
else
    echo "❌ ERROR: Failed to update trust policy"
    echo "💡 ROLLBACK: Restore from backup $BACKUP_FILE if needed"
    exit 1
fi

echo ""
echo "🧪 VERIFICATION: Testing updated trust policy..."

# Verify the policy was applied
echo "🔍 Retrieving updated trust policy..."
aws iam get-role --role-name "$ROLE_NAME" --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition' --output json

echo ""
echo "✅ AWS OIDC TRUST POLICY UPDATE COMPLETED!"
echo "==========================================="
echo ""
echo "📋 Summary:"
echo "  ✅ Role: $ROLE_NAME updated"
echo "  ✅ Repository: $NEW_REPO configured"
echo "  ✅ Backup: $BACKUP_FILE created"
echo ""
echo "📝 Next Steps:"
echo "  1. Test OIDC authentication with updated repository name"
echo "  2. Run GitHub Actions workflows to validate"
echo "  3. Monitor CloudTrail for successful assumed role sessions"
echo ""
echo "🧪 Test Command:"
echo "  gh workflow run oidc-validation.yml --ref main"
echo ""
echo "🚀 OIDC trust policy successfully updated for repository name change!"