#!/bin/bash
set -e

echo "=== Phase 1: Repository Consolidation & Branch Management ==="

# enterprise-devsecops-superlab repository
echo "1. Processing enterprise-devsecops-superlab..."
read -p "Enter path to enterprise-devsecops-superlab repo: " REPO1_PATH

if [ -d "$REPO1_PATH" ]; then
    cd "$REPO1_PATH"
    git checkout n8n
    git merge feature/initial-setup --no-ff -m "Merge feature/initial-setup into n8n"
    git branch -d feature/initial-setup
    git push origin n8n
    git push origin --delete feature/initial-setup
    echo "✅ enterprise-devsecops-superlab: Merged and cleaned"
else
    echo "❌ Repository path not found: $REPO1_PATH"
fi

# peter-security-CI-CDpipelines repository  
echo "2. Processing peter-security-CI-CDpipelines..."
read -p "Enter path to peter-security-CI-CDpipelines repo: " REPO2_PATH

if [ -d "$REPO2_PATH" ]; then
    cd "$REPO2_PATH"
    git checkout S-lab
    git branch -D Fail-Tester-f6607c90-2696-4d5a-a9f0-6f5e047c94c5 2>/dev/null || echo "Branch already deleted locally"
    git push origin --delete Fail-Tester-f6607c90-2696-4d5a-a9f0-6f5e047c94c5 2>/dev/null || echo "Branch already deleted remotely"
    echo "✅ peter-security-CI-CDpipelines: Cleaned"
else
    echo "❌ Repository path not found: $REPO2_PATH"
fi

echo "=== Phase 1 Complete ==="