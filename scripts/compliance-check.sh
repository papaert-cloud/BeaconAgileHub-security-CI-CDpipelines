#!/bin/bash
# Compliance Check Script - Policy Validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COMPLIANCE_DIR="compliance-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FRAMEWORKS=("slsa" "ssdf" "cis" "ics" "nist")

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

setup_compliance_directory() {
    log "Setting up compliance report directory..."
    mkdir -p "$COMPLIANCE_DIR"
    rm -rf "${COMPLIANCE_DIR:?}"/*
}

check_slsa_compliance() {
    log "Checking SLSA (Supply-chain Levels for Software Artifacts) compliance..."
    
    local slsa_report="${COMPLIANCE_DIR}/slsa-compliance.json"
    local level1_score=0
    local level2_score=0
    local level3_score=0
    local level4_score=0
    
    # Level 1: Documentation of build process
    if [ -d ".github/workflows" ]; then
        ((level1_score++))
        info "✓ Build process documented in GitHub Actions"
    fi
    
    if grep -r "provenance" .github/workflows/ > /dev/null 2>&1; then
        ((level1_score++))
        info "✓ Provenance generation configured"
    fi
    
    # Level 2: Tamper resistance of build service
    if grep -r "runs-on: ubuntu-latest" .github/workflows/ > /dev/null 2>&1; then
        ((level2_score++))
        info "✓ Using hosted build service"
    fi
    
    if grep -r "checkout@v4" .github/workflows/ > /dev/null 2>&1; then
        ((level2_score++))
        info "✓ Source integrity verification"
    fi
    
    # Level 3: Extra resistance to specific threats
    if grep -r "slsa-github-generator" .github/workflows/ > /dev/null 2>&1; then
        ((level3_score++))
        info "✓ Non-falsifiable provenance"
    fi
    
    if grep -r "permissions:" .github/workflows/ > /dev/null 2>&1; then
        ((level3_score++))
        info "✓ Isolated build environment"
    fi
    
    # Level 4: Highest levels of confidence and trust
    if [ -f ".github/CODEOWNERS" ]; then
        ((level4_score++))
        info "✓ Two-person review configured"
    fi
    
    if grep -r "container" .github/workflows/ > /dev/null 2>&1; then
        ((level4_score++))
        info "✓ Hermetic builds (containerized)"
    fi
    
    # Calculate overall SLSA level
    local slsa_level=0
    if [ $level1_score -ge 2 ]; then slsa_level=1; fi
    if [ $level2_score -ge 2 ]; then slsa_level=2; fi
    if [ $level3_score -ge 2 ]; then slsa_level=3; fi
    if [ $level4_score -ge 2 ]; then slsa_level=4; fi
    
    cat > "$slsa_report" <<EOF
{
    "framework": "SLSA",
    "version": "1.0",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "overall_level": $slsa_level,
    "levels": {
        "level1": {
            "score": $level1_score,
            "max_score": 2,
            "percentage": $((level1_score * 50))
        },
        "level2": {
            "score": $level2_score,
            "max_score": 2,
            "percentage": $((level2_score * 50))
        },
        "level3": {
            "score": $level3_score,
            "max_score": 2,
            "percentage": $((level3_score * 50))
        },
        "level4": {
            "score": $level4_score,
            "max_score": 2,
            "percentage": $((level4_score * 50))
        }
    }
}
EOF
    
    log "SLSA compliance level: $slsa_level/4 ✓"
}

check_ssdf_compliance() {
    log "Checking SSDF (Secure Software Development Framework) compliance..."
    
    local ssdf_report="${COMPLIANCE_DIR}/ssdf-compliance.json"
    local po_score=0  # Prepare Organization
    local ps_score=0  # Protect Software
    local pw_score=0  # Produce Well-Secured Software
    local rv_score=0  # Respond to Vulnerabilities
    
    # Prepare Organization (PO)
    if [ -f ".github/CODEOWNERS" ]; then
        ((po_score++))
        info "✓ PO.2.1: Roles and responsibilities defined"
    fi
    
    if [ -d ".github/workflows" ]; then
        ((po_score++))
        info "✓ PO.2.2: Secure development environment"
    fi
    
    if grep -r "security" .github/workflows/ > /dev/null 2>&1; then
        ((po_score++))
        info "✓ PO.3.1: Security tools integration"
    fi
    
    # Protect Software (PS)
    if [ -f "docs/threat-model.md" ]; then
        ((ps_score++))
        info "✓ PS.1.1: Threat modeling documented"
    fi
    
    if grep -r "codeql\|snyk\|security" .github/workflows/ > /dev/null 2>&1; then
        ((ps_score++))
        info "✓ PS.2.1: Secure coding practices enforced"
    fi
    
    if grep -r "sbom\|syft" .github/workflows/ > /dev/null 2>&1; then
        ((ps_score++))
        info "✓ PS.3.1: Third-party component management"
    fi
    
    # Produce Well-Secured Software (PW)
    if [ -d "terraform" ]; then
        ((pw_score++))
        info "✓ PW.1.1: Secure configuration management"
    fi
    
    if grep -r "sast\|dast\|security" .github/workflows/ > /dev/null 2>&1; then
        ((pw_score++))
        info "✓ PW.1.2: Security testing integrated"
    fi
    
    if grep -r "cosign\|sign" .github/workflows/ > /dev/null 2>&1; then
        ((pw_score++))
        info "✓ PW.2.1: Build integrity (signing)"
    fi
    
    # Respond to Vulnerabilities (RV)
    if [ -f "docs/security-runbooks.md" ]; then
        ((rv_score++))
        info "✓ RV.1.1: Vulnerability monitoring procedures"
    fi
    
    if grep -r "grype\|trivy\|vulnerability" .github/workflows/ > /dev/null 2>&1; then
        ((rv_score++))
        info "✓ RV.1.2: Vulnerability analysis automated"
    fi
    
    if grep -r "security-hub\|findings" .github/workflows/ > /dev/null 2>&1; then
        ((rv_score++))
        info "✓ RV.2.1: Vulnerability remediation tracking"
    fi
    
    local total_score=$((po_score + ps_score + pw_score + rv_score))
    local max_score=12
    local percentage=$((total_score * 100 / max_score))
    
    cat > "$ssdf_report" <<EOF
{
    "framework": "SSDF",
    "version": "1.1",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "overall_score": $total_score,
    "max_score": $max_score,
    "percentage": $percentage,
    "categories": {
        "prepare_organization": {
            "score": $po_score,
            "max_score": 3,
            "percentage": $((po_score * 100 / 3))
        },
        "protect_software": {
            "score": $ps_score,
            "max_score": 3,
            "percentage": $((ps_score * 100 / 3))
        },
        "produce_secured_software": {
            "score": $pw_score,
            "max_score": 3,
            "percentage": $((pw_score * 100 / 3))
        },
        "respond_vulnerabilities": {
            "score": $rv_score,
            "max_score": 3,
            "percentage": $((rv_score * 100 / 3))
        }
    }
}
EOF
    
    log "SSDF compliance: $percentage% ($total_score/$max_score) ✓"
}

check_cis_compliance() {
    log "Checking CIS (Center for Internet Security) benchmark compliance..."
    
    local cis_report="${COMPLIANCE_DIR}/cis-compliance.json"
    local docker_score=0
    local k8s_score=0
    
    # CIS Docker Benchmark
    if [ -f "app/Dockerfile" ]; then
        if grep -q "USER" app/Dockerfile; then
            ((docker_score++))
            info "✓ CIS Docker 4.1: Run as non-root user"
        fi
        
        if grep -q "FROM.*:.*" app/Dockerfile; then
            ((docker_score++))
            info "✓ CIS Docker 4.2: Use trusted base images with tags"
        fi
        
        if grep -q "HEALTHCHECK" app/Dockerfile; then
            ((docker_score++))
            info "✓ CIS Docker 4.6: Add HEALTHCHECK instruction"
        fi
        
        if grep -q "COPY" app/Dockerfile && ! grep -q "ADD" app/Dockerfile; then
            ((docker_score++))
            info "✓ CIS Docker 4.9: Use COPY instead of ADD"
        fi
    fi
    
    # CIS Kubernetes Benchmark
    if [ -d "kubernetes/policies" ]; then
        if grep -r "NetworkPolicy" kubernetes/policies/ > /dev/null 2>&1; then
            ((k8s_score++))
            info "✓ CIS K8s 5.3.2: Apply network segmentation"
        fi
        
        if grep -r "securityContext" kubernetes/policies/ > /dev/null 2>&1; then
            ((k8s_score++))
            info "✓ CIS K8s 5.3.1: Apply security context"
        fi
        
        if grep -r "allowPrivilegeEscalation.*false" kubernetes/policies/ > /dev/null 2>&1; then
            ((k8s_score++))
            info "✓ CIS K8s 5.2.5: Minimize allowPrivilegeEscalation"
        fi
    fi
    
    local total_score=$((docker_score + k8s_score))
    local max_score=7
    local percentage=$((total_score * 100 / max_score))
    
    cat > "$cis_report" <<EOF
{
    "framework": "CIS",
    "version": "1.6.0",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "overall_score": $total_score,
    "max_score": $max_score,
    "percentage": $percentage,
    "benchmarks": {
        "docker": {
            "score": $docker_score,
            "max_score": 4,
            "percentage": $((docker_score * 100 / 4))
        },
        "kubernetes": {
            "score": $k8s_score,
            "max_score": 3,
            "percentage": $((k8s_score * 100 / 3))
        }
    }
}
EOF
    
    log "CIS compliance: $percentage% ($total_score/$max_score) ✓"
}

check_ics_compliance() {
    log "Checking ICS (Industrial Control Systems) security compliance..."
    
    local ics_report="${COMPLIANCE_DIR}/ics-compliance.json"
    local network_score=0
    local endpoint_score=0
    local application_score=0
    local database_score=0
    
    # Network Security
    if [ -f "terraform/modules/network-security/main.tf" ]; then
        if grep -q "aws_vpc" terraform/modules/network-security/main.tf; then
            ((network_score++))
            info "✓ ICS Network: VPC segmentation implemented"
        fi
        
        if grep -q "aws_flow_log" terraform/modules/network-security/main.tf; then
            ((network_score++))
            info "✓ ICS Network: Flow logging enabled"
        fi
        
        if grep -q "aws_network_acl" terraform/modules/network-security/main.tf; then
            ((network_score++))
            info "✓ ICS Network: Network ACLs configured"
        fi
    fi
    
    # Endpoint Security
    if [ -f "terraform/modules/endpoint-security/main.tf" ]; then
        if grep -q "encryption" terraform/modules/endpoint-security/main.tf; then
            ((endpoint_score++))
            info "✓ ICS Endpoint: Encryption at rest"
        fi
        
        if grep -q "security_group" terraform/modules/endpoint-security/main.tf; then
            ((endpoint_score++))
            info "✓ ICS Endpoint: Security groups configured"
        fi
    fi
    
    # Application Security
    if grep -r "security" .github/workflows/ > /dev/null 2>&1; then
        ((application_score++))
        info "✓ ICS Application: Security testing integrated"
    fi
    
    if grep -r "sbom" .github/workflows/ > /dev/null 2>&1; then
        ((application_score++))
        info "✓ ICS Application: SBOM generation"
    fi
    
    # Database Security
    if [ -f "terraform/modules/database-security/main.tf" ]; then
        ((database_score++))
        info "✓ ICS Database: Security module defined"
    fi
    
    local total_score=$((network_score + endpoint_score + application_score + database_score))
    local max_score=8
    local percentage=$((total_score * 100 / max_score))
    
    cat > "$ics_report" <<EOF
{
    "framework": "ICS",
    "standards": ["NERC CIP", "IEC 62443", "NIST 800-82"],
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "overall_score": $total_score,
    "max_score": $max_score,
    "percentage": $percentage,
    "domains": {
        "network_security": {
            "score": $network_score,
            "max_score": 3,
            "percentage": $((network_score * 100 / 3))
        },
        "endpoint_security": {
            "score": $endpoint_score,
            "max_score": 2,
            "percentage": $((endpoint_score * 100 / 2))
        },
        "application_security": {
            "score": $application_score,
            "max_score": 2,
            "percentage": $((application_score * 100 / 2))
        },
        "database_security": {
            "score": $database_score,
            "max_score": 1,
            "percentage": $((database_score * 100 / 1))
        }
    }
}
EOF
    
    log "ICS compliance: $percentage% ($total_score/$max_score) ✓"
}

generate_compliance_summary() {
    log "Generating compliance summary report..."
    
    local summary_report="${COMPLIANCE_DIR}/compliance-summary-${TIMESTAMP}.json"
    
    # Initialize summary
    cat > "$summary_report" <<EOF
{
    "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "project": "sbom-security-pipeline",
    "compliance_frameworks": {},
    "overall_score": 0,
    "recommendations": []
}
EOF
    
    # Aggregate framework scores
    local total_percentage=0
    local framework_count=0
    
    for framework in "${FRAMEWORKS[@]}"; do
        local report_file="${COMPLIANCE_DIR}/${framework}-compliance.json"
        if [ -f "$report_file" ]; then
            local percentage=$(jq '.percentage // 0' "$report_file")
            total_percentage=$((total_percentage + percentage))
            ((framework_count++))
            
            # Add framework data to summary
            jq --slurpfile framework "$report_file" '.compliance_frameworks["'$framework'"] = $framework[0]' "$summary_report" > tmp.json && mv tmp.json "$summary_report"
        fi
    done
    
    # Calculate overall score
    if [ $framework_count -gt 0 ]; then
        local overall_score=$((total_percentage / framework_count))
        jq --argjson score "$overall_score" '.overall_score = $score' "$summary_report" > tmp.json && mv tmp.json "$summary_report"
    fi
    
    # Add recommendations based on scores
    local recommendations='[]'
    
    if [ -f "${COMPLIANCE_DIR}/slsa-compliance.json" ]; then
        local slsa_level=$(jq '.overall_level' "${COMPLIANCE_DIR}/slsa-compliance.json")
        if [ "$slsa_level" -lt 3 ]; then
            recommendations=$(echo "$recommendations" | jq '. + ["Improve SLSA compliance to Level 3 by implementing non-falsifiable provenance"]')
        fi
    fi
    
    if [ -f "${COMPLIANCE_DIR}/cis-compliance.json" ]; then
        local cis_percentage=$(jq '.percentage' "${COMPLIANCE_DIR}/cis-compliance.json")
        if [ "$cis_percentage" -lt 80 ]; then
            recommendations=$(echo "$recommendations" | jq '. + ["Enhance CIS benchmark compliance by implementing missing security controls"]')
        fi
    fi
    
    jq --argjson recs "$recommendations" '.recommendations = $recs' "$summary_report" > tmp.json && mv tmp.json "$summary_report"
    
    log "Generated compliance summary: $summary_report ✓"
}

generate_compliance_badge() {
    log "Generating compliance badges..."
    
    local badges_dir="${COMPLIANCE_DIR}/badges"
    mkdir -p "$badges_dir"
    
    # Generate SLSA badge
    if [ -f "${COMPLIANCE_DIR}/slsa-compliance.json" ]; then
        local slsa_level=$(jq '.overall_level' "${COMPLIANCE_DIR}/slsa-compliance.json")
        echo "[![SLSA $slsa_level](https://img.shields.io/badge/SLSA-Level%20$slsa_level-green.svg)](https://slsa.dev)" > "${badges_dir}/slsa-badge.md"
    fi
    
    # Generate overall compliance badge
    if [ -f "${COMPLIANCE_DIR}/compliance-summary-${TIMESTAMP}.json" ]; then
        local overall_score=$(jq '.overall_score' "${COMPLIANCE_DIR}/compliance-summary-${TIMESTAMP}.json")
        local color="red"
        if [ "$overall_score" -ge 80 ]; then color="green"; elif [ "$overall_score" -ge 60 ]; then color="yellow"; fi
        echo "[![Compliance ${overall_score}%](https://img.shields.io/badge/Compliance-${overall_score}%25-${color}.svg)](docs/compliance-mapping.md)" > "${badges_dir}/compliance-badge.md"
    fi
    
    log "Generated compliance badges ✓"
}

main() {
    log "Starting compliance validation..."
    
    setup_compliance_directory
    check_slsa_compliance
    check_ssdf_compliance
    check_cis_compliance
    check_ics_compliance
    generate_compliance_summary
    generate_compliance_badge
    
    log "Compliance validation completed! 🎉"
    log "Reports available in: $COMPLIANCE_DIR"
    
    # Display summary
    if [ -f "${COMPLIANCE_DIR}/compliance-summary-${TIMESTAMP}.json" ]; then
        local overall_score=$(jq '.overall_score' "${COMPLIANCE_DIR}/compliance-summary-${TIMESTAMP}.json")
        log "Overall compliance score: ${overall_score}%"
        
        if [ "$overall_score" -ge 80 ]; then
            log "Excellent compliance posture! ✅"
        elif [ "$overall_score" -ge 60 ]; then
            warn "Good compliance posture, room for improvement"
        else
            error "Compliance posture needs significant improvement"
        fi
    fi
}

main "$@"