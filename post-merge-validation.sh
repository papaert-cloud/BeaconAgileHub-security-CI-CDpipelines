#!/bin/bash
# ✅ Post-Merge Validation Script

echo "✅ Post-Merge Validation Checklist"
echo "=================================="

# Check if merge was successful
if git log --oneline -1 | grep -q "Resolve workflow merge conflicts"; then
    echo "✅ Merge conflict resolution commit found"
else
    echo "❌ Merge resolution commit not found"
fi

# Validate workflow files exist
CRITICAL_WORKFLOWS=(
    ".github/workflows/enhanced-security-gates.yml"
    ".github/workflows/enhanced-ci-pipeline.yml" 
    ".github/workflows/eda-n8n-e2e-test.yml"
)

echo ""
echo "📁 Critical Workflow Files:"
for workflow in "${CRITICAL_WORKFLOWS[@]}"; do
    if [ -f "$workflow" ]; then
        echo "  ✅ $workflow"
    else
        echo "  ❌ $workflow MISSING"
    fi
done

# Check documentation
echo ""
echo "📚 Documentation Files:"
DOC_FILES=(
    "docs/N8N_EDA_INTEGRATION.md"
    "ansible-eda/rulebooks/security-automation.yml"
    "docker-compose/grafana-prometheus-monitoring.yml"
)

for doc in "${DOC_FILES[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ❌ $doc MISSING"
    fi
done

# Final syntax check
echo ""
echo "🔍 Final YAML Syntax Check:"
SYNTAX_ERRORS=0
for file in .github/workflows/*.yml; do
    if ! yq eval '.' "$file" >/dev/null 2>&1; then
        echo "  ❌ SYNTAX ERROR: $file"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo "  ✅ All YAML files have valid syntax"
else
    echo "  ❌ $SYNTAX_ERRORS YAML syntax errors found"
fi

echo ""
if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo "🎉 VALIDATION PASSED - Ready to merge S-lab → main!"
else
    echo "🚨 VALIDATION FAILED - Fix errors before merging"
fi
