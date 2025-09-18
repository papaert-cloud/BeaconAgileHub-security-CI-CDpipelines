#!/bin/bash
# Security Validation Script - Automated Security Testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPORT_DIR="security-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SEVERITY_THRESHOLD="medium"

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

setup_report_directory() {
    log "Setting up security report directory..."
    mkdir -p "$REPORT_DIR"
    rm -rf "${REPORT_DIR:?}"/*
}

check_prerequisites() {
    log "Checking security tools..."
    
    local tools=("syft" "grype" "trivy" "checkov" "docker" "kubectl")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log "All security tools available ✓"
}

generate_sbom() {
    log "Generating Software Bill of Materials (SBOM)..."
    
    # Generate SBOM for application
    if [ -f "app/requirements.txt" ] || [ -f "app/package.json" ]; then
        syft app/ -o cyclonedx-json="${REPORT_DIR}/app-sbom.json"
        syft app/ -o spdx-json="${REPORT_DIR}/app-sbom-spdx.json"
        log "Generated application SBOM ✓"
    fi
    
    # Generate SBOM for container image if Dockerfile exists
    if [ -f "app/Dockerfile" ]; then
        local image_name="sbom-security-pipeline:latest"
        docker build -t "$image_name" app/ > /dev/null 2>&1
        syft "$image_name" -o cyclonedx-json="${REPORT_DIR}/container-sbom.json"
        log "Generated container SBOM ✓"
    fi
    
    # Generate infrastructure SBOM
    if [ -d "terraform" ]; then
        find terraform/ -name "*.tf" -exec cat {} \; > "${REPORT_DIR}/infrastructure-manifest.txt"
        log "Generated infrastructure manifest ✓"
    fi
}

vulnerability_scanning() {
    log "Running vulnerability scans..."
    
    # Scan application dependencies
    if [ -f "${REPORT_DIR}/app-sbom.json" ]; then
        grype "sbom:${REPORT_DIR}/app-sbom.json" -o json --file "${REPORT_DIR}/app-vulnerabilities.json"
        grype "sbom:${REPORT_DIR}/app-sbom.json" -o table --file "${REPORT_DIR}/app-vulnerabilities.txt"
        
        local vuln_count=$(jq '.matches | length' "${REPORT_DIR}/app-vulnerabilities.json")
        info "Found $vuln_count vulnerabilities in application dependencies"
    fi
    
    # Scan container image
    if [ -f "${REPORT_DIR}/container-sbom.json" ]; then
        grype "sbom:${REPORT_DIR}/container-sbom.json" -o json --file "${REPORT_DIR}/container-vulnerabilities.json"
        
        local container_vuln_count=$(jq '.matches | length' "${REPORT_DIR}/container-vulnerabilities.json")
        info "Found $container_vuln_count vulnerabilities in container image"
    fi
    
    # Trivy filesystem scan
    if [ -d "app" ]; then
        trivy fs app/ --format json --output "${REPORT_DIR}/trivy-fs-scan.json"
        trivy fs app/ --format table --output "${REPORT_DIR}/trivy-fs-scan.txt"
        log "Completed filesystem vulnerability scan ✓"
    fi
}

infrastructure_security_scan() {
    log "Running infrastructure security scans..."
    
    # Terraform security scan with Checkov
    if [ -d "terraform" ]; then
        checkov -d terraform/ --framework terraform --output json --output-file "${REPORT_DIR}/terraform-security.json" || true
        checkov -d terraform/ --framework terraform --output cli --output-file "${REPORT_DIR}/terraform-security.txt" || true
        log "Completed Terraform security scan ✓"
    fi
    
    # Dockerfile security scan
    if [ -f "app/Dockerfile" ]; then
        checkov -f app/Dockerfile --framework dockerfile --output json --output-file "${REPORT_DIR}/dockerfile-security.json" || true
        trivy config app/Dockerfile --format json --output "${REPORT_DIR}/dockerfile-trivy.json"
        log "Completed Dockerfile security scan ✓"
    fi
    
    # Kubernetes manifest scan
    if [ -d "kubernetes" ]; then
        checkov -d kubernetes/ --framework kubernetes --output json --output-file "${REPORT_DIR}/k8s-security.json" || true
        trivy config kubernetes/ --format json --output "${REPORT_DIR}/k8s-trivy.json"
        log "Completed Kubernetes security scan ✓"
    fi
}

secrets_detection() {
    log "Running secrets detection..."
    
    # Detect secrets in codebase
    if command -v detect-secrets &> /dev/null; then
        detect-secrets scan --all-files --baseline .secrets.baseline > "${REPORT_DIR}/secrets-scan.json" 2>/dev/null || true
        log "Completed secrets detection ✓"
    else
        warn "detect-secrets not installed, skipping secrets scan"
    fi
    
    # Git history secrets scan
    if command -v gitleaks &> /dev/null; then
        gitleaks detect --source . --report-format json --report-path "${REPORT_DIR}/gitleaks-report.json" || true
        log "Completed git history secrets scan ✓"
    else
        warn "gitleaks not installed, skipping git history scan"
    fi
}

compliance_validation() {
    log "Running compliance validation..."
    
    # CIS benchmark validation
    if [ -f "app/Dockerfile" ]; then
        docker run --rm -v "$(pwd):/workspace" aquasec/trivy config /workspace/app/Dockerfile \
            --format json --output "${REPORT_DIR}/cis-docker-benchmark.json" || true
        log "Completed CIS Docker benchmark ✓"
    fi
    
    # SLSA provenance check
    if [ -d ".github/workflows" ]; then
        local slsa_score=0
        
        # Check for build process documentation
        if grep -r "slsa" .github/workflows/ > /dev/null 2>&1; then
            ((slsa_score++))
        fi
        
        # Check for tamper-resistant build service
        if grep -r "github-hosted" .github/workflows/ > /dev/null 2>&1; then
            ((slsa_score++))
        fi
        
        # Check for provenance generation
        if grep -r "provenance" .github/workflows/ > /dev/null 2>&1; then
            ((slsa_score++))
        fi
        
        echo "{\"slsa_level\": $slsa_score, \"max_level\": 4}" > "${REPORT_DIR}/slsa-compliance.json"
        log "SLSA compliance level: $slsa_score/4 ✓"
    fi
}

generate_security_report() {
    log "Generating comprehensive security report..."
    
    local report_file="${REPORT_DIR}/security-summary-${TIMESTAMP}.json"
    
    # Initialize report structure
    cat > "$report_file" <<EOF
{
    "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scan_version": "1.0.0",
    "project": "sbom-security-pipeline",
    "summary": {
        "total_vulnerabilities": 0,
        "critical_vulnerabilities": 0,
        "high_vulnerabilities": 0,
        "medium_vulnerabilities": 0,
        "low_vulnerabilities": 0,
        "compliance_score": 0,
        "security_score": 100
    },
    "findings": {
        "vulnerabilities": [],
        "secrets": [],
        "misconfigurations": [],
        "compliance_issues": []
    }
}
EOF
    
    # Aggregate vulnerability data
    if [ -f "${REPORT_DIR}/app-vulnerabilities.json" ]; then
        local app_vulns=$(jq '.matches | length' "${REPORT_DIR}/app-vulnerabilities.json")
        jq --argjson count "$app_vulns" '.summary.total_vulnerabilities += $count' "$report_file" > tmp.json && mv tmp.json "$report_file"
    fi
    
    if [ -f "${REPORT_DIR}/container-vulnerabilities.json" ]; then
        local container_vulns=$(jq '.matches | length' "${REPORT_DIR}/container-vulnerabilities.json")
        jq --argjson count "$container_vulns" '.summary.total_vulnerabilities += $count' "$report_file" > tmp.json && mv tmp.json "$report_file"
    fi
    
    # Calculate security score
    local total_vulns=$(jq '.summary.total_vulnerabilities' "$report_file")
    local security_score=$((100 - total_vulns))
    if [ $security_score -lt 0 ]; then
        security_score=0
    fi
    
    jq --argjson score "$security_score" '.summary.security_score = $score' "$report_file" > tmp.json && mv tmp.json "$report_file"
    
    log "Generated security summary report: $report_file ✓"
}

check_security_gates() {
    log "Checking security gates..."
    
    local exit_code=0
    
    # Check for critical vulnerabilities
    if [ -f "${REPORT_DIR}/app-vulnerabilities.json" ]; then
        local critical_vulns=$(jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' "${REPORT_DIR}/app-vulnerabilities.json")
        if [ "$critical_vulns" -gt 0 ]; then
            error "Security gate failed: $critical_vulns critical vulnerabilities found"
            exit_code=1
        fi
    fi
    
    # Check for high-severity misconfigurations
    if [ -f "${REPORT_DIR}/terraform-security.json" ]; then
        local high_misconfigs=$(jq '[.results.failed_checks[] | select(.severity == "HIGH")] | length' "${REPORT_DIR}/terraform-security.json" 2>/dev/null || echo "0")
        if [ "$high_misconfigs" -gt 0 ]; then
            warn "Security gate warning: $high_misconfigs high-severity misconfigurations found"
        fi
    fi
    
    # Check for secrets
    if [ -f "${REPORT_DIR}/secrets-scan.json" ]; then
        local secrets_count=$(jq '.results | length' "${REPORT_DIR}/secrets-scan.json" 2>/dev/null || echo "0")
        if [ "$secrets_count" -gt 0 ]; then
            error "Security gate failed: $secrets_count secrets detected"
            exit_code=1
        fi
    fi
    
    if [ $exit_code -eq 0 ]; then
        log "All security gates passed ✅"
    else
        error "Security gates failed ❌"
    fi
    
    return $exit_code
}

upload_to_security_hub() {
    log "Uploading findings to AWS Security Hub..."
    
    if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
        # Convert findings to ASFF format and upload
        if [ -f "${REPORT_DIR}/app-vulnerabilities.json" ]; then
            # This would be implemented to convert Grype output to ASFF format
            info "Security Hub integration would upload findings here"
        fi
    else
        warn "AWS CLI not configured, skipping Security Hub upload"
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove temporary Docker images
    docker image prune -f > /dev/null 2>&1 || true
    
    # Compress reports
    tar -czf "${REPORT_DIR}/security-reports-${TIMESTAMP}.tar.gz" -C "$REPORT_DIR" . --exclude="*.tar.gz"
    
    log "Security validation complete. Reports available in: $REPORT_DIR"
}

main() {
    log "Starting security validation..."
    
    setup_report_directory
    check_prerequisites
    generate_sbom
    vulnerability_scanning
    infrastructure_security_scan
    secrets_detection
    compliance_validation
    generate_security_report
    upload_to_security_hub
    
    local gate_result=0
    check_security_gates || gate_result=$?
    
    cleanup
    
    if [ $gate_result -eq 0 ]; then
        log "Security validation completed successfully! 🎉"
    else
        error "Security validation failed! Please review the findings."
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help] [--severity-threshold LEVEL]"
        echo "  --severity-threshold: Set minimum severity level (low|medium|high|critical)"
        exit 0
        ;;
    --severity-threshold)
        SEVERITY_THRESHOLD="$2"
        shift 2
        ;;
esac

main "$@"