# Autonomous Dependabot AI Guard Implementation Guide

## Overview

This guide documents the implementation of the enhanced Autonomous Dependabot AI Guard system with NIST SP 800-53 compliance, SLSA Level 3 attestations, and comprehensive security automation.

## Architecture

### Core Components

1. **Multi-Scanner Vulnerability Assessment**
   - Primary: Grype (comprehensive vulnerability database)
   - Secondary: OSV Scanner (Google's Open Source Vulnerabilities)
   - SARIF output for GitHub Code Scanning integration

2. **EPSS Risk Prioritization Engine**
   - Real-time EPSS (Exploit Prediction Scoring System) integration
   - Autonomous priority classification (P0-Critical to P3-Low)
   - SLA-based remediation timelines

3. **Policy Gate System**
   - Configurable severity thresholds
   - EPSS score limits
   - Semver bump detection and controls
   - License compliance validation

4. **SLSA Level 3 Compliance**
   - Build provenance attestation
   - Cryptographic signing
   - Supply chain integrity verification

## Implementation Details

### Key Improvements Implemented

#### 1. Fixed Package Installation Bug
**Issue**: `pip3 install requests pyyaml jq` - jq isn't a Python package
**Solution**: 
```bash
sudo apt-get update -y
sudo apt-get install -y jq git curl
pip3 install requests pyyaml
```

#### 2. Enhanced OSV Integration
**Issue**: OSV findings weren't merged with Grype results
**Solution**: Implemented union merge logic to combine both scanner outputs

#### 3. Concurrency Control
**Added**: Prevents multiple workflow runs from interfering
```yaml
concurrency:
  group: auto-guard-${{ github.event.pull_request.number || github.run_id }}
  cancel-in-progress: true
```

#### 4. Semver Bump Detection
**Added**: Automatic detection of major/minor/patch version changes
- Blocks major bumps by default (configurable)
- Requires human review for breaking changes

#### 5. SARIF Upload
**Added**: Integration with GitHub Code Scanning
```yaml
- name: 📤 Upload SARIF for Code Scanning
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: grype.sarif
```

#### 6. Central Policy Gate
**Added**: Modular policy enforcement with configurable thresholds
```yaml
env:
  EPSS_MAX: "0.50"
  BLOCK_SEVERITIES: "High|Critical"
  ALLOW_MAJOR_BUMPS: "false"
```

#### 7. Improved Scheduling
**Added**: Dual-schedule for DST handling
```yaml
schedule:
  - cron: "0 11 * * *"  # 06:00 CT (summer)
  - cron: "0 12 * * *"  # 06:00 CST (winter)
```

#### 8. Artifact Retention Optimization
**Changed**: From 2555 days (7 years) to 90 days with S3 mirroring recommendation

### Configuration Options

#### Environment Variables
```yaml
env:
  EPSS_MAX: "0.50"              # Block if any CVE EPSS > 0.50
  BLOCK_SEVERITIES: "High|Critical"  # Severity patterns to block
  ALLOW_MAJOR_BUMPS: "false"    # Require human review for major bumps
  SLSA_LEVEL: "3"               # SLSA compliance level
  NIST_FRAMEWORK: "SP-800-53-R5" # NIST framework version
```

#### Policy Thresholds
- **P0-Critical**: EPSS ≥ 0.2 + CVSS ≥ 7.0 (4h SLA)
- **P1-High**: EPSS ≥ 0.1 + CVSS ≥ 7.0 (24h SLA)
- **P2-Medium**: Lower EPSS + CVSS ≥ 4.0 (72h SLA)
- **P3-Low**: Remaining vulnerabilities (7d SLA)

## NIST SP 800-53 Control Mapping

### Implemented Controls

| Control | Name | Implementation | Automation Level |
|---------|------|----------------|------------------|
| SI-2 | Flaw Remediation | EPSS-prioritized vulnerability management | Fully Automated |
| SI-3 | Malicious Code Protection | Multi-scanner detection + SBOM verification | Fully Automated |
| SI-4 | Information System Monitoring | Continuous dependency monitoring | Fully Automated |
| SI-7 | Software Integrity | SLSA L3 build provenance + attestations | Fully Automated |
| CM-8 | Component Inventory | Automated SBOM generation (SPDX) | Fully Automated |
| SA-10 | Developer Configuration Management | License compliance + supply chain verification | Fully Automated |

### Compliance Evidence Generation

The system automatically generates comprehensive compliance evidence:

```json
{
  "assessment_timestamp": "2024-01-15T10:30:00Z",
  "system_identifier": "org/repo",
  "nist_framework": "SP-800-53-R5",
  "system_categorization": "MODERATE",
  "controls_implemented": {
    "SI-2": {
      "status": "IMPLEMENTED",
      "automation_level": "FULLY_AUTOMATED",
      "evidence": ["epss-analysis.json", "vulnerability-assessment.json"]
    }
  }
}
```

## Workflow Testing Guide

### 1. Test Vulnerability Detection
```bash
# Create a test dependency with known vulnerabilities
echo "requests==2.25.1" >> requirements.txt
git add requirements.txt
git commit -m "test: add vulnerable dependency"
git push
```

### 2. Test Semver Detection
```bash
# Create a Dependabot-style PR title
git checkout -b test-semver
echo "# Test" > test.txt
git add test.txt
git commit -m "Bump requests from 2.25.1 to 3.0.0"
```

### 3. Test Policy Gates
```bash
# Modify thresholds in workflow
EPSS_MAX: "0.01"  # Very strict threshold
BLOCK_SEVERITIES: "Medium|High|Critical"  # Block more severities
```

### 4. Verify SARIF Upload
1. Check GitHub Security tab after workflow run
2. Verify Code Scanning alerts appear
3. Confirm SARIF file contains expected vulnerabilities

## Troubleshooting

### Common Issues

#### 1. EPSS API Rate Limiting
**Symptoms**: Empty EPSS scores, API timeout errors
**Solution**: 
- Implement exponential backoff
- Cache EPSS results
- Batch CVE requests (max 100 per call)

#### 2. License Detection Failures
**Symptoms**: `licensee detect` fails or returns empty results
**Solution**:
- Ensure repository has a LICENSE file
- Check gem installation: `gem install licensee`
- Use `continue-on-error: true` for non-critical failures

#### 3. SARIF Upload Failures
**Symptoms**: Code Scanning tab shows no results
**Solution**:
- Verify SARIF file exists: `ls -la grype.sarif`
- Check file format: `jq . grype.sarif`
- Ensure proper permissions: `security-events: write`

#### 4. Merge Failures
**Symptoms**: Auto-merge doesn't trigger despite "safe" status
**Solution**:
- Check branch protection rules
- Verify PR is from Dependabot: `github.actor == 'dependabot[bot]'`
- Ensure all status checks pass

### Debug Commands

```bash
# Check workflow logs
gh run list --workflow="Autonomous Dependabot AI Guard"
gh run view <run-id> --log

# Validate YAML syntax
yamllint .github/workflows/dependabot-guard.yml

# Test policy logic locally
python3 -c "
import json
with open('epss-analysis.json') as f:
    data = json.load(f)
    critical = [v for v in data if v['priority'] == 'P0-CRITICAL']
    print(f'Critical vulnerabilities: {len(critical)}')
"
```

## Security Considerations

### 1. Token Permissions
Ensure minimal required permissions:
```yaml
permissions:
  contents: read
  pull-requests: write
  security-events: write
  attestations: write
  id-token: write
  actions: read
```

### 2. Secret Management
- Never hardcode credentials
- Use OIDC for AWS authentication
- Rotate tokens regularly

### 3. Supply Chain Security
- Pin action versions: `@v4` not `@main`
- Verify action checksums
- Use official actions from trusted publishers

## Monitoring and Alerting

### Key Metrics to Monitor

1. **Vulnerability Detection Rate**
   - Total vulnerabilities found per scan
   - Critical/High severity trends
   - EPSS score distributions

2. **Policy Gate Effectiveness**
   - Auto-merge success rate
   - Human review requirements
   - False positive rates

3. **Compliance Posture**
   - NIST control implementation status
   - Evidence generation success
   - Attestation verification rates

### Alerting Thresholds

- **Critical**: P0 vulnerabilities detected (immediate notification)
- **High**: Policy gate failures (24h SLA)
- **Medium**: License compliance issues (review required)
- **Low**: SARIF upload failures (monitoring only)

## Future Enhancements

### Planned Improvements

1. **Enhanced License Scanning**
   - Dependency license analysis (not just repo license)
   - Integration with ScanCode Toolkit
   - Custom license policy definitions

2. **Advanced EPSS Integration**
   - Historical EPSS trend analysis
   - Custom scoring models
   - Integration with threat intelligence feeds

3. **Expanded SLSA Compliance**
   - SLSA Level 4 requirements
   - Enhanced build isolation
   - Reproducible builds verification

4. **AI/ML Enhancements**
   - Vulnerability impact prediction
   - False positive reduction
   - Automated remediation suggestions

## Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly**
   - Review high-risk alerts
   - Update vulnerability databases
   - Check policy gate effectiveness

2. **Monthly**
   - Update action versions
   - Review EPSS thresholds
   - Analyze compliance metrics

3. **Quarterly**
   - Security control assessment
   - Policy refinement
   - Performance optimization

### Getting Help

- **Documentation**: This guide and inline comments
- **Logs**: GitHub Actions workflow logs
- **Issues**: Create GitHub issues for bugs/enhancements
- **Security**: Follow responsible disclosure for security issues

---

*Last Updated: January 2024*
*Version: 2.0*
*Compliance: NIST SP 800-53 R5, SLSA Level 3*