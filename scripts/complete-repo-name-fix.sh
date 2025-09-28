#!/bin/bash
# 🎯 COMPLETE REPOSITORY NAME STANDARDIZATION FIX
# Addresses all remaining references and AWS OIDC integration

set -euo pipefail

echo "🎯 COMPLETE REPOSITORY NAME STANDARDIZATION"
echo "==========================================="
echo ""

# Configuration (now targeting the actual current repo name)
OLD_REPO="BeaconAgileHub-security-CI-CDpipelines"
NEW_REPO="peter-security-CI-CDpipelines"  # Note: lowercase 'p' to match actual repo
OLD_FULL="papaert-cloud/BeaconAgileHub-security-CI-CDpipelines"
NEW_FULL="papaert-cloud/peter-security-CI-CDpipelines"  # Match GitHub repo case
OLD_MIXED_CASE="Peter-security-CI-CDpipelines"  # Fix mixed case references
OLD_BADGE="papaert/sbom"

echo "📋 Configuration:"
echo "  Old Repository: $OLD_REPO"
echo "  New Repository: $NEW_REPO"
echo "  Old Full Path: $OLD_FULL"
echo "  New Full Path: $NEW_FULL"
echo "  Mixed Case Fix: $OLD_MIXED_CASE → $NEW_REPO"
echo "  Badge Fix: $OLD_BADGE → $NEW_FULL"
echo ""

# Step 1: Fix all remaining references found in your scan
echo "1️⃣ FIXING DOCUMENTATION REFERENCES"
echo "================================="

# Fix the docs/PHASE1-EXECUTION.md references
if [ -f "docs/PHASE1-EXECUTION.md" ]; then
    echo "📝 Updating docs/PHASE1-EXECUTION.md..."
    sed -i "s|$OLD_REPO|$NEW_REPO|g" docs/PHASE1-EXECUTION.md
    sed -i "s|$OLD_FULL|$NEW_FULL|g" docs/PHASE1-EXECUTION.md
    echo "  ✅ Documentation updated"
else
    echo "  ℹ️  docs/PHASE1-EXECUTION.md not found"
fi

# Fix the scripts/phase1-repo-cleanup.sh references
if [ -f "scripts/phase1-repo-cleanup.sh" ]; then
    echo "📝 Updating scripts/phase1-repo-cleanup.sh..."
    sed -i "s|$OLD_REPO|$NEW_REPO|g" scripts/phase1-repo-cleanup.sh
    sed -i "s|$OLD_FULL|$NEW_FULL|g" scripts/phase1-repo-cleanup.sh
    # Fix the specific prompt text
    sed -i "s|Enter path to BeaconAgileHub-security-CI-CDpipelines repo|Enter path to $NEW_REPO repo|g" scripts/phase1-repo-cleanup.sh
    sed -i "s|Processing BeaconAgileHub-security-CI-CDpipelines|Processing $NEW_REPO|g" scripts/phase1-repo-cleanup.sh
    echo "  ✅ Cleanup script updated"
else
    echo "  ℹ️  scripts/phase1-repo-cleanup.sh not found"
fi

# Step 2: Fix mixed case references (Peter- vs peter-)
echo ""
echo "2️⃣ FIXING CASE CONSISTENCY"
echo "=========================="

# Find and fix any mixed case references
find . -type f \\( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.json" -o -name "*.sh" \\) ! -path "./.git/*" -exec grep -l "$OLD_MIXED_CASE" {} \\; 2>/dev/null | while read -r file; do
    echo "📝 Fixing case consistency in: $file"
    sed -i "s|$OLD_MIXED_CASE|$NEW_REPO|g" "$file"
    sed -i "s|papaert-cloud/$OLD_MIXED_CASE|$NEW_FULL|g" "$file"
done

# Step 3: Update AWS OIDC trust policy JSON file to match actual repo case
echo ""
echo "3️⃣ UPDATING AWS OIDC CONFIGURATION"
echo "=================================="

if [ -f "aws/oidc-trust-policy-update.json" ]; then
    echo "📝 Updating OIDC trust policy JSON..."
    # Fix case in the trust policy JSON
    sed -i "s|Peter-security-CI-CDpipelines|peter-security-CI-CDpipelines|g" aws/oidc-trust-policy-update.json
    echo "  ✅ OIDC trust policy JSON updated"
else
    echo "  ⚠️  Creating OIDC trust policy JSON..."
    mkdir -p aws
    cat > aws/oidc-trust-policy-update.json << 'EOFOIDC'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubOIDCTrust",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::005965605891:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:repository": "papaert-cloud/peter-security-CI-CDpipelines"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:papaert-cloud/peter-security-CI-CDpipelines:*"
        }
      }
    }
  ]
}
EOFOIDC
    echo "  ✅ OIDC trust policy JSON created"
fi

# Step 4: Update README.md badge references
echo ""
echo "4️⃣ FIXING README BADGE REFERENCES"
echo "================================="

if [ -f "README.md" ]; then
    echo "📝 Updating README.md badges..."
    
    # Fix the papaert/sbom badge references to point to correct repo
    sed -i "s|github.com/papaert/sbom|github.com/$NEW_FULL|g" README.md
    sed -i "s|papaert/sbom|$NEW_FULL|g" README.md
    
    # Update any other incorrect badge references
    sed -i "s|$OLD_REPO|$NEW_REPO|g" README.md
    sed -i "s|$OLD_FULL|$NEW_FULL|g" README.md
    
    echo "  ✅ README badges updated"
else
    echo "  ℹ️  README.md not found"
fi

# Step 5: Final verification
echo ""
echo "5️⃣ FINAL VERIFICATION"
echo "===================="

echo "🔍 Scanning for remaining old references..."
echo ""

# Check for BeaconAgileHub references
BEACON_REFS=$(grep -r "$OLD_REPO" . --exclude-dir=.git --exclude="*.log" --exclude="complete-repo-name-fix.sh" 2>/dev/null | wc -l)
echo "BeaconAgileHub references remaining: $BEACON_REFS"

# Check for old full path references
FULL_PATH_REFS=$(grep -r "$OLD_FULL" . --exclude-dir=.git --exclude="*.log" --exclude="complete-repo-name-fix.sh" 2>/dev/null | wc -l)
echo "Old full path references remaining: $FULL_PATH_REFS"

# Check for mixed case references
MIXED_CASE_REFS=$(grep -r "$OLD_MIXED_CASE" . --exclude-dir=.git --exclude="*.log" --exclude="complete-repo-name-fix.sh" 2>/dev/null | wc -l)
echo "Mixed case references remaining: $MIXED_CASE_REFS"

# Check for old badge references
BADGE_REFS=$(grep -r "$OLD_BADGE" . --exclude-dir=.git --exclude="*.log" --exclude="complete-repo-name-fix.sh" 2>/dev/null | wc -l)
echo "Old badge references remaining: $BADGE_REFS"

TOTAL_REFS=$((BEACON_REFS + FULL_PATH_REFS + MIXED_CASE_REFS + BADGE_REFS))

echo ""
echo "📊 VERIFICATION SUMMARY:"
echo "  Total old references remaining: $TOTAL_REFS"

if [ $TOTAL_REFS -eq 0 ]; then
    echo "  ✅ ALL REFERENCES SUCCESSFULLY UPDATED!"
    echo "  🎉 Repository name standardization complete!"
else
    echo "  ⚠️  $TOTAL_REFS references still need attention"
    echo "  🔍 Showing remaining references:"
    grep -r "$OLD_REPO\\|$OLD_FULL\\|$OLD_MIXED_CASE\\|$OLD_BADGE" . --exclude-dir=.git --exclude="*.log" --exclude="complete-repo-name-fix.sh" 2>/dev/null | head -10 || echo "No additional references found"
fi

# Step 6: Git status and next steps
echo ""
echo "6️⃣ GIT STATUS AND NEXT STEPS"
echo "============================"

echo "📊 Git status:"
git status --porcelain | head -10

CHANGED_FILES=$(git status --porcelain | wc -l)
echo "Changed files: $CHANGED_FILES"

echo ""
echo "🚀 NEXT STEPS:"
echo "1. Review changes: git diff"
echo "2. Apply AWS OIDC trust policy: ./aws/update-aws-oidc.sh"
echo "3. Commit changes: git add . && git commit -m 'Standardize repository name references'"
echo "4. Test OIDC: gh workflow run repository-name-validation.yml --ref docs-reorg"
echo "5. Validate integration: check GitHub Actions for successful OIDC authentication"
echo ""
echo "✅ REPOSITORY NAME STANDARDIZATION SCRIPT COMPLETED!"