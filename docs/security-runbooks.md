# Security Runbooks - Incident Response Procedures

## Overview
This document provides step-by-step procedures for responding to security incidents in our DevSecOps pipeline with ICS security integration.

## Incident Classification

### Severity Levels
| Level | Description | Response Time | Escalation |
|-------|-------------|---------------|------------|
| **P0 - Critical** | Production system compromise, data breach | 15 minutes | CISO, Legal |
| **P1 - High** | Security control failure, vulnerability exploitation | 1 hour | Security Team Lead |
| **P2 - Medium** | Policy violation, suspicious activity | 4 hours | Security Analyst |
| **P3 - Low** | Minor configuration issue, informational alert | 24 hours | DevOps Team |

## Runbook 1: Container Security Incident

### Scenario: Malicious Container Detected

#### Detection Indicators
- Falco alert: Unauthorized process execution
- High-severity vulnerability in running container
- Suspicious network connections from pod

#### Response Steps

1. **Immediate Containment (0-15 minutes)**
   ```bash
   # Isolate the affected pod
   kubectl label pod <pod-name> security.incident=true
   kubectl patch networkpolicy default-deny -p '{"spec":{"podSelector":{"matchLabels":{"security.incident":"true"}}}}'
   
   # Scale down the deployment
   kubectl scale deployment <deployment-name> --replicas=0
   ```

2. **Investigation (15-60 minutes)**
   ```bash
   # Collect pod logs
   kubectl logs <pod-name> --previous > incident-logs.txt
   
   # Get pod details
   kubectl describe pod <pod-name> > pod-details.txt
   
   # Check security events
   kubectl get events --field-selector involvedObject.name=<pod-name>
   ```

3. **Analysis (1-4 hours)**
   ```bash
   # Scan container image
   trivy image <image-name> --format json --output image-scan.json
   
   # Check SBOM for malicious components
   syft <image-name> -o cyclonedx-json | jq '.components[] | select(.name | contains("malicious"))'
   
   # Review Falco alerts
   kubectl logs -n falco-system daemonset/falco | grep <pod-name>
   ```

4. **Remediation (4-24 hours)**
   ```bash
   # Update image with patched version
   kubectl set image deployment/<deployment-name> <container-name>=<new-image>
   
   # Apply security policies
   kubectl apply -f kubernetes/policies/enhanced-security.yaml
   
   # Verify remediation
   kubectl rollout status deployment/<deployment-name>
   ```

## Runbook 2: Supply Chain Compromise

### Scenario: Malicious Dependency Detected

#### Detection Indicators
- Snyk alert: High-severity vulnerability in dependency
- SBOM analysis shows suspicious package
- Unusual network activity from application

#### Response Steps

1. **Immediate Assessment (0-30 minutes)**
   ```bash
   # Check affected applications
   grep -r "<malicious-package>" . --include="*.json" --include="*.lock"
   
   # Review SBOM for impact analysis
   syft . -o cyclonedx-json | jq '.components[] | select(.name == "<malicious-package>")'
   
   # Stop affected deployments
   kubectl scale deployment <affected-deployments> --replicas=0
   ```

2. **Impact Analysis (30-120 minutes)**
   ```bash
   # Generate dependency tree
   npm ls --depth=0 > dependency-tree.txt
   
   # Check for data exfiltration
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject
   
   # Review application logs
   kubectl logs deployment/<app-name> --since=24h | grep -i "error\|exception\|unauthorized"
   ```

3. **Containment (2-6 hours)**
   ```bash
   # Remove malicious dependency
   npm uninstall <malicious-package>
   
   # Update to safe version
   npm install <safe-package>@<safe-version>
   
   # Regenerate SBOM
   syft . -o cyclonedx-json=updated-sbom.json
   
   # Rebuild and redeploy
   docker build -t <app-name>:patched .
   kubectl set image deployment/<app-name> <container>=<app-name>:patched
   ```

## Runbook 3: Infrastructure Compromise

### Scenario: Unauthorized AWS Access Detected

#### Detection Indicators
- GuardDuty alert: Unusual API activity
- CloudTrail shows unauthorized resource creation
- Security Hub finding: Compromised credentials

#### Response Steps

1. **Immediate Isolation (0-15 minutes)**
   ```bash
   # Disable compromised IAM user/role
   aws iam attach-user-policy --user-name <compromised-user> --policy-arn arn:aws:iam::aws:policy/AWSDenyAll
   
   # Revoke active sessions
   aws iam delete-access-key --user-name <compromised-user> --access-key-id <access-key>
   
   # Enable CloudTrail logging if disabled
   aws cloudtrail start-logging --name <trail-name>
   ```

2. **Forensic Collection (15-60 minutes)**
   ```bash
   # Export CloudTrail logs
   aws logs create-export-task --log-group-name CloudTrail/SecurityAudit --from 1640995200000 --to 1641081600000 --destination s3://security-forensics-bucket
   
   # Get GuardDuty findings
   aws guardduty get-findings --detector-id <detector-id> --finding-ids <finding-id>
   
   # Check for unauthorized resources
   aws ec2 describe-instances --query 'Reservations[*].Instances[?LaunchTime>=`2024-01-01`]'
   ```

3. **Damage Assessment (1-4 hours)**
   ```bash
   # Review resource modifications
   aws config get-resource-config-history --resource-type AWS::EC2::Instance --resource-id <instance-id>
   
   # Check data access
   aws s3api get-bucket-logging --bucket <sensitive-bucket>
   
   # Analyze network traffic
   aws ec2 describe-flow-logs --filter Name=resource-id,Values=<vpc-id>
   ```

4. **Recovery (4-24 hours)**
   ```bash
   # Rotate all credentials
   aws iam create-access-key --user-name <user-name>
   aws secretsmanager rotate-secret --secret-id <secret-arn>
   
   # Rebuild compromised infrastructure
   terragrunt destroy --target=module.compromised_resource
   terragrunt apply --target=module.compromised_resource
   
   # Update security groups
   aws ec2 revoke-security-group-ingress --group-id <sg-id> --protocol tcp --port 22 --cidr 0.0.0.0/0
   ```

## Runbook 4: Data Breach Response

### Scenario: Unauthorized Data Access Detected

#### Detection Indicators
- Database audit log shows unusual queries
- Large data export detected
- External data transfer alerts

#### Response Steps

1. **Immediate Containment (0-30 minutes)**
   ```bash
   # Block suspicious IP addresses
   aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 443 --source-group <deny-sg>
   
   # Disable compromised database user
   mysql -h <rds-endpoint> -u admin -p -e "REVOKE ALL PRIVILEGES ON *.* FROM '<compromised-user>'@'%';"
   
   # Enable enhanced monitoring
   aws rds modify-db-instance --db-instance-identifier <db-id> --monitoring-interval 60
   ```

2. **Data Impact Assessment (30-120 minutes)**
   ```bash
   # Review database audit logs
   aws rds download-db-log-file-portion --db-instance-identifier <db-id> --log-file-name audit/server_audit.log
   
   # Check data export activities
   aws s3api list-objects-v2 --bucket <data-export-bucket> --query 'Contents[?LastModified>=`2024-01-01`]'
   
   # Analyze application logs for data access
   kubectl logs deployment/<app-name> | grep -i "select\|export\|download"
   ```

3. **Legal and Compliance (2-6 hours)**
   ```bash
   # Generate compliance report
   aws securityhub get-findings --filters '{"Title":[{"Value":"Data Breach","Comparison":"EQUALS"}]}'
   
   # Document affected records
   mysql -h <rds-endpoint> -u admin -p -e "SELECT COUNT(*) FROM sensitive_table WHERE last_accessed >= '2024-01-01';"
   
   # Prepare breach notification
   echo "Data breach incident report - $(date)" > breach-report.txt
   ```

## Runbook 5: CI/CD Pipeline Compromise

### Scenario: Malicious Code Injection in Pipeline

#### Detection Indicators
- CodeQL alert: High-severity security issue
- Unusual build artifacts
- Unauthorized pipeline modifications

#### Response Steps

1. **Pipeline Isolation (0-15 minutes)**
   ```bash
   # Disable affected workflows
   gh workflow disable <workflow-name>
   
   # Revoke GitHub tokens
   gh auth refresh --scopes repo,workflow
   
   # Lock repository branches
   gh api repos/:owner/:repo/branches/main/protection -X PUT --field required_status_checks='{"strict":true,"contexts":["security-scan"]}'
   ```

2. **Code Analysis (15-60 minutes)**
   ```bash
   # Run security scan on recent commits
   git log --oneline --since="24 hours ago" | while read commit; do
     codeql database analyze --format=json --output=scan-$commit.json
   done
   
   # Check for secrets in commits
   git log -p --since="24 hours ago" | grep -i "password\|token\|key\|secret"
   
   # Analyze build artifacts
   docker run --rm -v $(pwd):/workspace aquasec/trivy fs /workspace
   ```

3. **Artifact Quarantine (1-4 hours)**
   ```bash
   # Remove malicious artifacts
   docker rmi <malicious-image>
   gh release delete <compromised-release>
   
   # Rebuild clean artifacts
   git revert <malicious-commit>
   docker build -t <app-name>:clean .
   
   # Update deployment with clean image
   kubectl set image deployment/<app-name> <container>=<app-name>:clean
   ```

## Communication Templates

### Internal Notification
```
SECURITY INCIDENT ALERT - P<severity>

Incident ID: INC-<timestamp>
Detected: <detection-time>
Affected Systems: <systems-list>
Initial Assessment: <brief-description>

Immediate Actions Taken:
- <action-1>
- <action-2>

Next Steps:
- <next-action>
- ETA: <estimated-time>

Contact: Security Team (<contact-info>)
```

### External Notification (if required)
```
Security Incident Notification

We are writing to inform you of a security incident that may have affected your data.

What Happened: <incident-description>
What Information Was Involved: <data-types>
What We Are Doing: <response-actions>
What You Can Do: <user-actions>

For questions, contact: <contact-information>
```

## Post-Incident Activities

### Lessons Learned Session
1. Timeline reconstruction
2. Root cause analysis
3. Control effectiveness review
4. Process improvement recommendations

### Documentation Updates
1. Update runbooks based on lessons learned
2. Enhance monitoring rules
3. Improve detection capabilities
4. Update training materials

### Metrics Collection
- Incident response time
- Mean time to detection (MTTD)
- Mean time to containment (MTTC)
- Mean time to recovery (MTTR)

## Emergency Contacts

| Role | Primary | Secondary | Escalation |
|------|---------|-----------|------------|
| Security Team Lead | <phone> | <email> | CISO |
| DevOps Lead | <phone> | <email> | CTO |
| Legal Counsel | <phone> | <email> | General Counsel |
| Communications | <phone> | <email> | CMO |