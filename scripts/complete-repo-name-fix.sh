#!/bin/bash
# Complete Repository Name Standardization Script
# Fixes all remaining references to use correct case: peter-security-CI-CDpipelines

set -e

# Repository name variables
OLD_REPO_BEACON="peter-security-CI-CDpipelines"
OLD_REPO_PETER_CAPS="peter-security-CI-CDpipelines"
NEW_REPO="peter-security-CI-CDpipelines"
OLD_FULL_BEACON="papaert-cloud/peter-security-CI-CDpipelines"
OLD_FULL_PETER_CAPS="papaert-cloud/peter-security-CI-CDpipelines"
NEW_FULL="papaert-cloud/peter-security-CI-CDpipelines"

echo "🔧 Starting comprehensive repository name standardization..."
echo "Target: $NEW_FULL"
echo ""

# Count current references
echo "📊 Current reference count:"
BEACON_COUNT=$(grep -r "$OLD_REPO_BEACON" . --exclude-dir=.git --exclude="*.log" --exclude-dir=.terraform 2>/dev/null | wc -l || echo "0")
PETER_COUNT=$(grep -r "$OLD_REPO_PETER_CAPS" . --exclude-dir=.git --exclude="*.log" --exclude-dir=.terraform 2>/dev/null | wc -l || echo "0")
echo "  BeaconAgileHub references: $BEACON_COUNT"
echo "  Peter- (caps) references: $PETER_COUNT"
echo ""

# 1. Fix documentation files
echo "📝 Updating documentation..."
find . -name "*.md" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_REPO_BEACON|$NEW_REPO|g" {} \;
find . -name "*.md" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_FULL_BEACON|$NEW_FULL|g" {} \;
find . -name "*.md" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_REPO_PETER_CAPS|$NEW_REPO|g" {} \;
find . -name "*.md" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_FULL_PETER_CAPS|$NEW_FULL|g" {} \;

# 2. Fix script files
echo "🔧 Updating scripts..."
find scripts/ -name "*.sh" -exec sed -i "s|$OLD_REPO_BEACON|$NEW_REPO|g" {} \; 2>/dev/null || true
find scripts/ -name "*.sh" -exec sed -i "s|$OLD_FULL_BEACON|$NEW_FULL|g" {} \; 2>/dev/null || true
find scripts/ -name "*.sh" -exec sed -i "s|$OLD_REPO_PETER_CAPS|$NEW_REPO|g" {} \; 2>/dev/null || true
find scripts/ -name "*.sh" -exec sed -i "s|$OLD_FULL_PETER_CAPS|$NEW_FULL|g" {} \; 2>/dev/null || true

# 3. Fix workflow files
echo "⚙️ Updating GitHub workflows..."
if [ -d ".github/workflows" ]; then
    find .github/workflows -name "*.yml" -exec sed -i "s|$OLD_REPO_BEACON|$NEW_REPO|g" {} \;
    find .github/workflows -name "*.yml" -exec sed -i "s|$OLD_FULL_BEACON|$NEW_FULL|g" {} \;
    find .github/workflows -name "*.yml" -exec sed -i "s|$OLD_REPO_PETER_CAPS|$NEW_REPO|g" {} \;
    find .github/workflows -name "*.yml" -exec sed -i "s|$OLD_FULL_PETER_CAPS|$NEW_FULL|g" {} \;
fi

# 4. Fix JSON configuration files
echo "📋 Updating JSON configurations..."
find . -name "*.json" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_REPO_BEACON|$NEW_REPO|g" {} \;
find . -name "*.json" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_FULL_BEACON|$NEW_FULL|g" {} \;
find . -name "*.json" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_REPO_PETER_CAPS|$NEW_REPO|g" {} \;
find . -name "*.json" -not -path "./.git/*" -not -path "./.terraform/*" -exec sed -i "s|$OLD_FULL_PETER_CAPS|$NEW_FULL|g" {} \;

# 5. Fix YAML configuration files
echo "📄 Updating YAML configurations..."
find . -name "*.yml" -o -name "*.yaml" -not -path "./.git/*" -not -path "./.terraform/*" | while read file; do
    sed -i "s|$OLD_REPO_BEACON|$NEW_REPO|g" "$file" 2>/dev/null || true
    sed -i "s|$OLD_FULL_BEACON|$NEW_FULL|g" "$file" 2>/dev/null || true
    sed -i "s|$OLD_REPO_PETER_CAPS|$NEW_REPO|g" "$file" 2>/dev/null || true
    sed -i "s|$OLD_FULL_PETER_CAPS|$NEW_FULL|g" "$file" 2>/dev/null || true
done

echo ""
echo "✅ Repository name standardization complete!"

# Final count
echo "📊 Final reference count:"
BEACON_FINAL=$(grep -r "$OLD_REPO_BEACON" . --exclude-dir=.git --exclude="*.log" --exclude-dir=.terraform 2>/dev/null | wc -l || echo "0")
PETER_FINAL=$(grep -r "$OLD_REPO_PETER_CAPS" . --exclude-dir=.git --exclude="*.log" --exclude-dir=.terraform 2>/dev/null | wc -l || echo "0")
echo "  BeaconAgileHub references remaining: $BEACON_FINAL"
echo "  Peter- (caps) references remaining: $PETER_FINAL"

if [ "$BEACON_FINAL" -eq 0 ] && [ "$PETER_FINAL" -eq 0 ]; then
    echo "🎉 All repository references successfully standardized!"
else
    echo "⚠️ Some references may still exist. Manual review recommended."
fi

echo ""
echo "📋 Changed files:"
git status --porcelain | head -20

echo ""
echo "🚀 Next steps:"
echo "1. Review changes: git diff"
echo "2. Update AWS OIDC trust policy"
echo "3. Commit changes: git add -A && git commit -m 'Standardize repository name references'"
echo "4. Test OIDC authentication"