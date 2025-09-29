#!/bin/bash
# 🔧 CRITICAL Repository Fix Script
set -euo pipefail

echo "🚀 Starting Emergency DevSecOps Pipeline Fix..."

# Fix 1: Repository Reference Correction (CRITICAL)
echo "🔄 Checking for repository references..."
WRONG_REPO="BeaconAgileHub-security-CI-CDpipelines"  
CORRECT_REPO="peter-security-CI-CDpipelines"

# Create backup before changes
if [ -d ".github/workflows" ]; then
    cp -r .github/workflows .github/workflows.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Workflow backup created"
fi

# Global replacement in workflow files
CHANGED_FILES=0
if [ -d ".github/workflows" ]; then
    find .github/workflows -name "*.yml" -exec grep -l "$WRONG_REPO" {} \; | while read file; do
        sed -i "s|$WRONG_REPO|$CORRECT_REPO|g" "$file"
        echo "  Fixed: $file"
        ((CHANGED_FILES++))
    done
    
    find .github/workflows -name "*.yaml" -exec grep -l "$WRONG_REPO" {} \; | while read file; do
        sed -i "s|$WRONG_REPO|$CORRECT_REPO|g" "$file"
        echo "  Fixed: $file"
        ((CHANGED_FILES++))
    done
fi

# Verify no references remain
REMAINING=$(grep -r "$WRONG_REPO" .github/workflows/ --include="*.yml" --include="*.yaml" 2>/dev/null | wc -l || echo "0")
echo "✅ Repository references check complete. Remaining: $REMAINING"

# Fix 2: Terraform Formatting (CRITICAL)
echo "🏗️ Formatting Terraform files..."
if command -v terraform >/dev/null 2>&1; then
    # Format all terraform files
    terraform fmt -recursive .
    echo "✅ Terraform formatting applied"
    
    # Validate formatting
    if terraform fmt -check -recursive . >/dev/null 2>&1; then
        echo "✅ All Terraform files properly formatted"
    else
        echo "⚠️ Some files may need manual formatting"
        terraform fmt -check -recursive . || true
    fi
else
    echo "⚠️ Terraform not installed - install and run: terraform fmt -recursive ."
fi

echo "🎯 Emergency fixes completed!"