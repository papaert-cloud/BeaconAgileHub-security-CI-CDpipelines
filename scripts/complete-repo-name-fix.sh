#!/bin/bash
# 🎯 COMPLETE REPOSITORY NAME STANDARDIZATION FIX

set -euo pipefail

OLD_REPO="peter-security-CI-CDpipelines"
NEW_REPO="peter-security-CI-CDpipelines"
OLD_FULL="papaert-cloud/peter-security-CI-CDpipelines"
NEW_FULL="papaert-cloud/peter-security-CI-CDpipelines"

echo "🔍 Updating repository references..."

# Update specific files identified in search
find . -type f \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh" \) \
  ! -path "./.git/*" \
  -exec sed -i "s|$OLD_REPO|$NEW_REPO|g; s|$OLD_FULL|$NEW_FULL|g" {} \;

echo "✅ Repository references updated"
