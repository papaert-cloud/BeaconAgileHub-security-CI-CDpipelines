#!/bin/bash
# 🔍 Critical Configuration Review Script

echo "🔍 Reviewing Critical DevSecOps Configurations"
echo "============================================="

# Check enhanced security gates
echo "🛡️ Enhanced Security Gates Configuration:"
if grep -q "enhanced-security-gates" .github/workflows/enhanced-security-gates.yml; then
    echo "  ✅ Enhanced security gates preserved"
else
    echo "  ❌ Enhanced security gates missing"
fi

# Check EDA integration
echo ""
echo "⚡ EDA Integration Configuration:"
if grep -q "eda-n8n-e2e-test" .github/workflows/eda-n8n-e2e-test.yml 2>/dev/null; then
    echo "  ✅ EDA N8N integration preserved"
else
    echo "  ❌ EDA N8N integration missing"
fi

# Check monitoring integration
echo ""
echo "📊 Monitoring Configuration:"
if ls docker-compose/grafana-prometheus-monitoring.yml >/dev/null 2>&1; then
    echo "  ✅ Monitoring stack configuration preserved"
else
    echo "  ❌ Monitoring configuration missing"
fi

# Check environment variables
echo ""
echo "🌍 Environment Configuration:"
ENV_FILES=(
    ".github/workflows/enhanced-ci-pipeline.yml"
    ".github/workflows/enhanced-security-gates.yml"
)

for file in "${ENV_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "FAIL_ON_SECURITY" "$file"; then
            echo "  ✅ $file has proper environment config"
        else
            echo "  ⚠️ $file may be missing environment variables"
        fi
    fi
done

# Check secrets configuration
echo ""
echo "🔐 Secrets Configuration:"
if grep -rq "secrets: inherit" .github/workflows/; then
    echo "  ✅ Secrets inheritance configured"
else
    echo "  ⚠️ Secrets inheritance may need review"
fi

# Check concurrency configuration
echo ""
echo "🔄 Concurrency Configuration:"
if grep -rq "concurrency:" .github/workflows/; then
    echo "  ✅ Concurrency groups configured"
else
    echo "  ⚠️ Concurrency groups may need review"
fi

echo ""
echo "📋 Review completed. Address any ❌ or ⚠️ items before merging."
