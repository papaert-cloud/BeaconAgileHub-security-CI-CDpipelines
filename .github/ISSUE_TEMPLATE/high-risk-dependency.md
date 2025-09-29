---
name: 🚨 High-Risk Dependency Alert
about: Autonomous AI system detected high-risk dependency requiring human review
title: '🚨 High-Risk Dependency: [PACKAGE_NAME]'
labels: ['security', 'high-priority', 'autonomous-alert', 'dependencies']
assignees: []
---

## 🤖 Autonomous AI Analysis Results

**Package**: `[PACKAGE_NAME]`
**Risk Level**: 🔴 **[RISK_LEVEL]**
**EPSS Score**: [EPSS_SCORE] (exploit probability)
**CVSS Score**: [CVSS_SCORE] (impact severity)
**SLA**: [SLA_HOURS] hours

## 🎯 Vulnerability Details

### Critical CVEs Identified
- **[CVE_ID]**: [DESCRIPTION]
  - EPSS: [EPSS_SCORE] (Top [PERCENTILE]% exploit probability)
  - CVSS: [CVSS_SCORE] ([SEVERITY])
  - Known Exploits: [YES/NO]

## 📋 Required Actions

### Immediate (within [SLA_HOURS] hours)
- [ ] **Security team review** of vulnerability impact
- [ ] **Risk assessment** for production systems
- [ ] **Remediation decision**: Patch/Accept/Mitigate

### Documentation
- [ ] **Risk acceptance** (if applicable)
- [ ] **Remediation plan** (if patching)
- [ ] **Incident response** (if actively exploited)

## 🔍 Evidence Package

**Compliance Evidence**: Available in workflow artifacts
- SLSA L3 SBOM with provenance
- Multi-scanner vulnerability assessment
- EPSS-enhanced risk analysis
- NIST compliance documentation

**Workflow Run**: [WORKFLOW_URL]
**Pull Request**: [PR_URL]

## 🛡️ NIST Control Mapping

- **SI-2 (Flaw Remediation)**: Automated detection ✅, Human decision required ⏳
- **SI-4 (System Monitoring)**: Continuous monitoring active ✅
- **RA-5 (Vulnerability Scanning)**: Multi-scanner assessment complete ✅

## 🚨 Escalation Path

**If SLA exceeded**:
1. Notify CISO/Security Lead
2. Initiate emergency change process
3. Consider system isolation if actively exploited

---
*This issue was automatically created by the Autonomous AI Dependabot System*
*Framework: NIST SP 800-53 R5 | SLSA: Level 3 | Evidence: Cryptographically Signed*