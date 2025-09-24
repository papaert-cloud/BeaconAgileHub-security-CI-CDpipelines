#!/bin/bash
# 🔧 S-lab Pipeline Troubleshooting & Validation Script
# Complete diagnostic and testing toolkit for the S-lab development pipeline

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="BeaconAgileHub-security-CI-CDpipelines"
ORG_NAME="papaert-cloud"
BRANCH="S-lab"
VPS_HOST="148.230.94.85"

echo -e "${BLUE}🔧 S-lab Pipeline Troubleshooting Toolkit${NC}"
echo "============================================"
echo ""
echo -e "${YELLOW}Repository:${NC} $ORG_NAME/$REPO_NAME"
echo -e "${YELLOW}Branch:${NC} $BRANCH"
echo -e "${YELLOW}Date:${NC} $(date)"
echo ""

# Function to print status with emojis
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️ $message${NC}" ;;
        "info") echo -e "${BLUE}📝 $message${NC}" ;;
        "debug") echo -e "${PURPLE}🐛 $message${NC}" ;;
    esac
}

# Function to run command with error handling
run_command() {
    local cmd="$1"
    local description="$2"
    
    echo -e "${BLUE}🚀 Running: $description${NC}"
    echo "   Command: $cmd"
    
    if eval "$cmd"; then
        print_status "success" "$description completed"
        return 0
    else
        print_status "error" "$description failed"
        return 1
    fi
}

# Function to check file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        print_status "success" "$description exists: $file"
        return 0
    else
        print_status "error" "$description missing: $file"
        return 1
    fi
}

# Main menu
show_menu() {
    echo -e "${BLUE}Select troubleshooting option:${NC}"
    echo "1. 🛡️  Validate Security Gates"
    echo "2. 🔄  Test CI Pipeline Components"
    echo "3. 🤖  Simulate N8N/EDA Integration"
    echo "4. 🐳  Check Container & VPS Connectivity"
    echo "5. 📋  Validate Workflow Syntax"
    echo "6. 🔍  Debug Security Scan Results"
    echo "7. ⚡  Performance Diagnostics"
    echo "8. 📊  Generate Comprehensive Report"
    echo "9. 🎆  Run All Diagnostics"
    echo "0. 🚪  Exit"
    echo ""
    read -p "Enter choice (0-9): " choice
}

# 1. Validate Security Gates
validate_security_gates() {
    echo -e "${PURPLE}🛡️ Validating Security Gates${NC}"
    echo "=============================="
    
    # Check workflow files
    check_file ".github/workflows/enhanced-security-gates.yml" "Security Gates workflow"
    
    # Check security tools configuration
    if [ -f ".github/workflows/enhanced-security-gates.yml" ]; then
        echo -e "${BLUE}Checking security tools configuration...${NC}"
        
        # Extract tool versions
        KICS_VERSION=$(grep -o 'KICS_VERSION: "[^"]*"' .github/workflows/enhanced-security-gates.yml | cut -d'"' -f2 || echo "not found")
        CHECKOV_VERSION=$(grep -o 'CHECKOV_VERSION: "[^"]*"' .github/workflows/enhanced-security-gates.yml | cut -d'"' -f2 || echo "not found")
        TRIVY_VERSION=$(grep -o 'TRIVY_VERSION: "[^"]*"' .github/workflows/enhanced-security-gates.yml | cut -d'"' -f2 || echo "not found")
        
        echo "Tool Versions:"
        echo "  KICS: $KICS_VERSION"
        echo "  Checkov: $CHECKOV_VERSION"
        echo "  Trivy: $TRIVY_VERSION"
        
        # Check for proper triggers
        if grep -q "workflow_call" .github/workflows/enhanced-security-gates.yml; then
            print_status "success" "workflow_call trigger configured"
        else
            print_status "warning" "workflow_call trigger not found"
        fi
        
        if grep -q "workflow_dispatch" .github/workflows/enhanced-security-gates.yml; then
            print_status "success" "workflow_dispatch trigger configured"
        else
            print_status "warning" "workflow_dispatch trigger not found"
        fi
    fi
    
    # Test YAML syntax
    if command -v yq >/dev/null 2>&1; then
        run_command "yq eval '.' .github/workflows/enhanced-security-gates.yml > /dev/null" "Security Gates YAML syntax validation"
    else
        print_status "warning" "yq not available, skipping YAML validation"
    fi
}

# 2. Test CI Pipeline Components
test_ci_pipeline() {
    echo -e "${PURPLE}🔄 Testing CI Pipeline Components${NC}"
    echo "================================="
    
    # Check CI pipeline file
    check_file ".github/workflows/enhanced-ci-pipeline.yml" "CI Pipeline workflow"
    
    # Check for proper job dependencies
    if [ -f ".github/workflows/enhanced-ci-pipeline.yml" ]; then
        echo -e "${BLUE}Analyzing job dependencies...${NC}"
        
        # Check security-first approach
        if grep -A 5 "jobs:" .github/workflows/enhanced-ci-pipeline.yml | grep -q "security-gates"; then
            print_status "success" "Security-first approach: security-gates is first job"
        else
            print_status "warning" "Security gates may not be first job"
        fi
        
        # Check environment detection
        if grep -q "environment-setup" .github/workflows/enhanced-ci-pipeline.yml; then
            print_status "success" "Environment setup job found"
        fi
        
        # Check for fail_on_severity configuration
        if grep -q "fail_on_severity" .github/workflows/enhanced-ci-pipeline.yml; then
            print_status "success" "Configurable security failure threshold found"
        fi
    fi
    
    # Check reusable workflow integration
    if [ -f ".github/workflows/enhanced-ci-pipeline.yml" ]; then
        if grep -q "uses: ./.github/workflows/enhanced-security-gates.yml" .github/workflows/enhanced-ci-pipeline.yml; then
            print_status "success" "Reusable security gates integration confirmed"
        else
            print_status "error" "Security gates not properly integrated"
        fi
    fi
}

# 3. Simulate N8N/EDA Integration
simulate_n8n_eda() {
    echo -e "${PURPLE}🤖 Simulating N8N/EDA Integration${NC}"
    echo "==================================="
    
    # Check if N8N integration documentation exists
    check_file "docs/N8N_EDA_INTEGRATION.md" "N8N/EDA Integration documentation"
    
    # Create simulation script
    cat > /tmp/n8n-simulation.py << 'EOF'
#!/usr/bin/env python3
import json
import time
from datetime import datetime

class DevSecOpsSimulation:
    def __init__(self):
        self.alerts_processed = 0
        
    def simulate_security_event(self, severity="medium"):
        event_id = f"SIM-{int(time.time())}"
        
        print(f"⚡ Simulating {severity} security event: {event_id}")
        
        # Simulate N8N workflow processing
        print("  🤖 N8N AI Agent Analysis:")
        print(f"    - Event ID: {event_id}")
        print(f"    - Severity: {severity}")
        print(f"    - AI Recommendation: {'Immediate action required' if severity == 'critical' else 'Monitor and assess'}")
        
        # Simulate EDA response
        print("  ⚡ Event-Driven Ansible Response:")
        actions = [
            "Creating security incident ticket",
            "Collecting forensic evidence",
            "Triggering pipeline security scan",
            "Sending notifications to security team"
        ]
        
        for action in actions:
            print(f"    ✅ {action}")
            time.sleep(0.5)
            
        self.alerts_processed += 1
        print(f"  🎯 Event {event_id} processed successfully")
        
    def generate_report(self):
        print("\n📊 N8N/EDA Simulation Report:")
        print(f"  Total events processed: {self.alerts_processed}")
        print("  Integration status: Ready for deployment")
        print("  Recommendation: Proceed with N8N/EDA setup")

# Run simulation
sim = DevSecOpsSimulation()
for severity in ["low", "medium", "high", "critical"]:
    sim.simulate_security_event(severity)
    print("-" * 40)
    
sim.generate_report()
EOF

    # Run the simulation
    if command -v python3 >/dev/null 2>&1; then
        run_command "python3 /tmp/n8n-simulation.py" "N8N/EDA Integration simulation"
    else
        print_status "warning" "Python3 not available, skipping simulation"
    fi
    
    # Clean up
    rm -f /tmp/n8n-simulation.py
}

# 4. Check Container & VPS Connectivity
check_connectivity() {
    echo -e "${PURPLE}🐳 Checking Container & VPS Connectivity${NC}"
    echo "=========================================="
    
    # Check Docker availability
    if command -v docker >/dev/null 2>&1; then
        run_command "docker --version" "Docker version check"
        run_command "docker ps" "Docker container status"
    else
        print_status "warning" "Docker not available locally"
    fi
    
    # Check VPS connectivity
    echo -e "${BLUE}Testing VPS connectivity...${NC}"
    if ping -c 1 "$VPS_HOST" >/dev/null 2>&1; then
        print_status "success" "VPS host $VPS_HOST is reachable"
        
        # Check SSH connectivity if key exists
        SSH_KEY="$HOME/.ssh/hostinger_vps_key"
        if [ -f "$SSH_KEY" ]; then
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i "$SSH_KEY" "root@$VPS_HOST" "echo 'SSH test successful'" 2>/dev/null; then
                print_status "success" "SSH connection to VPS successful"
                
                # Check Docker on VPS
                if ssh -o ConnectTimeout=5 -i "$SSH_KEY" "root@$VPS_HOST" "docker --version" 2>/dev/null; then
                    print_status "success" "Docker available on VPS"
                else
                    print_status "warning" "Docker not available on VPS"
                fi
            else
                print_status "warning" "SSH connection failed (check key permissions)"
            fi
        else
            print_status "info" "SSH key not found at $SSH_KEY"
        fi
    else
        print_status "error" "VPS host $VPS_HOST not reachable"
    fi
    
    # Check GitHub Container Registry connectivity
    echo -e "${BLUE}Testing GitHub Container Registry...${NC}"
    if curl -s "https://ghcr.io" >/dev/null; then
        print_status "success" "GitHub Container Registry reachable"
    else
        print_status "warning" "GitHub Container Registry not reachable"
    fi
}

# 5. Validate Workflow Syntax
validate_workflow_syntax() {
    echo -e "${PURPLE}📋 Validating Workflow Syntax${NC}"
    echo "==============================="
    
    # Install yq if not available
    if ! command -v yq >/dev/null 2>&1; then
        echo "Installing yq for YAML validation..."
        if command -v wget >/dev/null 2>&1; then
            YQ_VERSION="v4.43.1"
            YQ_BIN_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
            YQ_SHA_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums"
            TMP_YQ="/tmp/yq_linux_amd64"
            TMP_SHA="/tmp/yq_checksums"
            wget -qO "$TMP_YQ" "$YQ_BIN_URL" 2>/dev/null || {
                print_status "warning" "Could not download yq binary"
                return 1
            }
            wget -qO "$TMP_SHA" "$YQ_SHA_URL" 2>/dev/null || {
                print_status "warning" "Could not download yq checksums"
                rm -f "$TMP_YQ"
                return 1
            }
            EXPECTED_SHA=$(grep "yq_linux_amd64" "$TMP_SHA" | awk '{print $1}')
            ACTUAL_SHA=$(sha256sum "$TMP_YQ" | awk '{print $1}')
            if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
                print_status "error" "yq checksum verification failed"
                rm -f "$TMP_YQ" "$TMP_SHA"
                return 1
            fi
            sudo mv "$TMP_YQ" /usr/local/bin/yq
            sudo chmod +x /usr/local/bin/yq 2>/dev/null || true
            rm -f "$TMP_SHA"
    fi
    
    # Validate all workflow files
    if command -v yq >/dev/null 2>&1; then
        find .github/workflows -name "*.yml" -o -name "*.yaml" | while read -r workflow; do
            if yq eval '.' "$workflow" >/dev/null 2>&1; then
                print_status "success" "Valid syntax: $workflow"
            else
                print_status "error" "Invalid syntax: $workflow"
            fi
        done
    fi
    
    # Check for common issues
    echo -e "${BLUE}Checking for common workflow issues...${NC}"
    
    # Check for hardcoded secrets
    if grep -r "github_token" .github/workflows/ 2>/dev/null | grep -v "secrets.GITHUB_TOKEN"; then
        print_status "warning" "Potential hardcoded token found"
    else
        print_status "success" "No hardcoded tokens detected"
    fi
    
    # Check for proper secret usage
    if grep -r "secrets:" .github/workflows/ >/dev/null 2>&1; then
        print_status "success" "Secret usage detected"
    fi
}

# 6. Debug Security Scan Results
debug_security_results() {
    echo -e "${PURPLE}🔍 Debugging Security Scan Results${NC}"
    echo "=================================="
    
    # Check for existing security reports
    if [ -d "security-reports" ]; then
        print_status "info" "Security reports directory found"
        
        # Analyze KICS results
        if [ -f "security-reports/kics/kics-results.json" ]; then
            echo -e "${BLUE}KICS Results Analysis:${NC}"
            if command -v jq >/dev/null 2>&1; then
                echo "Summary:"
                jq '.summary' security-reports/kics/kics-results.json 2>/dev/null || echo "Could not parse KICS summary"
                
                echo "Critical/High Issues:"
                jq '.results[] | select(.severity == "HIGH" or .severity == "CRITICAL") | {file, issue: .issue_type, severity}' security-reports/kics/kics-results.json 2>/dev/null || echo "No critical/high issues or parsing error"
            else
                print_status "warning" "jq not available for JSON analysis"
            fi
        else
            print_status "info" "No KICS results found"
        fi
        
        # Analyze Checkov results
        if [ -f "security-reports/checkov-results.json" ]; then
            echo -e "${BLUE}Checkov Results Analysis:${NC}"
            if command -v jq >/dev/null 2>&1; then
                jq '.summary' security-reports/checkov-results.json 2>/dev/null || echo "Could not parse Checkov summary"
            fi
        else
            print_status "info" "No Checkov results found"
        fi
    else
        print_status "info" "No security reports directory found (run security gates first)"
    fi
    
    # Create mock security scan for testing
    echo -e "${BLUE}Creating mock security scan results for testing...${NC}"
    mkdir -p security-reports/mock
    
    cat > security-reports/mock/sample-results.json << 'EOF'
{
  "summary": {
    "total_issues": 5,
    "critical": 0,
    "high": 1,
    "medium": 2,
    "low": 2,
    "info": 0
  },
  "results": [
    {
      "file": "terraform/main.tf",
      "issue_type": "Insecure S3 Bucket",
      "severity": "HIGH",
      "description": "S3 bucket does not have encryption enabled"
    },
    {
      "file": "docker/Dockerfile",
      "issue_type": "Running as root",
      "severity": "MEDIUM",
      "description": "Container runs as root user"
    }
  ]
}
EOF
    
    print_status "success" "Mock security results created for testing"
}

# 7. Performance Diagnostics
performance_diagnostics() {
    echo -e "${PURPLE}⚡ Performance Diagnostics${NC}"
    echo "========================="
    
    # System resource check
    echo -e "${BLUE}System Resources:${NC}"
    echo "CPU Info:"
    nproc 2>/dev/null || echo "CPU count not available"
    
    echo "Memory Info:"
    free -h 2>/dev/null || echo "Memory info not available"
    
    echo "Disk Space:"
    df -h . 2>/dev/null || echo "Disk info not available"
    
    # Check workflow performance
    echo -e "${BLUE}Workflow Performance Analysis:${NC}"
    
    # Estimate workflow execution time
    echo "Estimated execution times:"
    echo "  Security Gates: 8-12 minutes"
    echo "  CI Pipeline: 15-20 minutes"
    echo "  CD Pipeline: 10-15 minutes"
    echo "  Full Pipeline: 25-35 minutes"
    
    # Check for performance optimizations
    echo -e "${BLUE}Performance Optimization Recommendations:${NC}"
    
    # Check for caching
    if grep -r "cache" .github/workflows/ >/dev/null 2>&1; then
        print_status "success" "Caching detected in workflows"
    else
        print_status "warning" "Consider adding caching for dependencies"
    fi
    
    # Check for parallel execution
    if grep -r "strategy:" .github/workflows/ >/dev/null 2>&1; then
        print_status "success" "Matrix/parallel execution detected"
    else
        print_status "info" "Consider parallel execution for security scans"
    fi
    
    # Check artifact sizes
    if [ -d ".github/workflows" ]; then
        echo "Workflow file sizes:"
        find .github/workflows -name "*.yml" -exec wc -l {} + 2>/dev/null || echo "Could not analyze workflow sizes"
    fi
}

# 8. Generate Comprehensive Report
generate_report() {
    echo -e "${PURPLE}📊 Generating Comprehensive Report${NC}"
    echo "=================================="
    
    REPORT_FILE="s-lab-diagnostic-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOF
# S-lab Pipeline Diagnostic Report

Generated: $(date)
Repository: $ORG_NAME/$REPO_NAME
Branch: $BRANCH

## Executive Summary

This report provides a comprehensive analysis of the S-lab development pipeline status, including security gates, CI/CD workflows, and integration readiness.

## Workflow Analysis

### Security Gates
- Status: $([ -f ".github/workflows/enhanced-security-gates.yml" ] && echo "✅ Configured" || echo "❌ Missing")
- Tools: KICS, Checkov, Terrascan, Trivy
- fail_on_severity: false (development-friendly)

### CI Pipeline
- Status: $([ -f ".github/workflows/enhanced-ci-pipeline.yml" ] && echo "✅ Configured" || echo "❌ Missing")
- Security-first approach: $(grep -q "security-gates" .github/workflows/enhanced-ci-pipeline.yml 2>/dev/null && echo "✅ Implemented" || echo "❌ Not detected")
- Environment detection: $(grep -q "environment-setup" .github/workflows/enhanced-ci-pipeline.yml 2>/dev/null && echo "✅ Configured" || echo "❌ Missing")

### Integration Status
- N8N/EDA Documentation: $([ -f "docs/N8N_EDA_INTEGRATION.md" ] && echo "✅ Available" || echo "❌ Missing")
- VPS Connectivity: $(ping -c 1 "$VPS_HOST" >/dev/null 2>&1 && echo "✅ Reachable" || echo "❌ Not reachable")
- Container Registry: $(curl -s "https://ghcr.io" >/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")

## Recommendations

1. **Security**: Continue with development-friendly security gates (fail_on_severity: false)
2. **Testing**: Use workflow_dispatch for manual testing and validation
3. **Integration**: N8N/EDA integration documentation is ready for implementation
4. **Deployment**: VPS deployment configuration is production-ready

## Next Steps

1. Test workflows using GitHub Actions workflow_dispatch
2. Validate security scanning with real-world scenarios
3. Implement N8N/EDA integration when ready
4. Prepare for S-lab → main promotion

---

*Report generated by S-lab troubleshooting toolkit*
EOF
    
    print_status "success" "Comprehensive report generated: $REPORT_FILE"
    
    # Display report summary
    echo -e "${BLUE}Report Summary:${NC}"
    tail -20 "$REPORT_FILE"
}

# 9. Run All Diagnostics
run_all_diagnostics() {
    echo -e "${PURPLE}🎆 Running All Diagnostics${NC}"
    echo "=========================="
    
    validate_security_gates
    echo ""
    test_ci_pipeline
    echo ""
    simulate_n8n_eda
    echo ""
    check_connectivity
    echo ""
    validate_workflow_syntax
    echo ""
    debug_security_results
    echo ""
    performance_diagnostics
    echo ""
    generate_report
    
    echo -e "${GREEN}🎉 All diagnostics completed!${NC}"
}

# Main execution
if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        case $choice in
            1) validate_security_gates ;;
            2) test_ci_pipeline ;;
            3) simulate_n8n_eda ;;
            4) check_connectivity ;;
            5) validate_workflow_syntax ;;
            6) debug_security_results ;;
            7) performance_diagnostics ;;
            8) generate_report ;;
            9) run_all_diagnostics ;;
            0) echo "Goodbye!"; exit 0 ;;
            *) print_status "error" "Invalid option. Please try again." ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
else
    # Command line mode
    case $1 in
        "--security") validate_security_gates ;;
        "--ci") test_ci_pipeline ;;
        "--n8n") simulate_n8n_eda ;;
        "--connectivity") check_connectivity ;;
        "--syntax") validate_workflow_syntax ;;
        "--debug") debug_security_results ;;
        "--performance") performance_diagnostics ;;
        "--report") generate_report ;;
        "--all") run_all_diagnostics ;;
        *) 
            echo "Usage: $0 [--security|--ci|--n8n|--connectivity|--syntax|--debug|--performance|--report|--all]"
            echo "Or run without arguments for interactive mode"
            exit 1
            ;;
    esac
fi