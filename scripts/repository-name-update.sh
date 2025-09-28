#!/bin/bash
# 🔄 COMPREHENSIVE REPOSITORY NAME CHANGE SCRIPT
# Updates all references from BeaconAgileHub-security-CI-CDpipelines to peter-security-CI-CDpipelines

set -euo pipefail

echo "🔄 COMPREHENSIVE REPOSITORY NAME UPDATE"
echo "====================================="
echo ""

# Configuration
OLD_REPO="BeaconAgileHub-security-CI-CDpipelines"
NEW_REPO="peter-security-CI-CDpipelines"
OLD_FULL="papaert-cloud/BeaconAgileHub-security-CI-CDpipelines"
NEW_FULL="papaert-cloud/peter-security-CI-CDpipelines"
OLD_BADGE_REPO="papaert/sbom"  # Fix existing badge inconsistencies
NEW_BADGE_REPO="papaert-cloud/peter-security-CI-CDpipelines"

echo "📋 Configuration:"
echo "  Old Repository: $OLD_REPO"
echo "  New Repository: $NEW_REPO"
echo "  Old Full Path: $OLD_FULL"
echo "  New Full Path: $NEW_FULL"
echo "  Badge Fix: $OLD_BADGE_REPO → $NEW_BADGE_REPO"
echo ""

# Create backup
echo "💾 Creating backup..."
git tag "backup-before-name-change-$(date +%Y%m%d-%H%M%S)" || echo "Backup tag creation failed (may already exist)"

# Function to update files with repository references
update_repository_references() {
    local file_pattern="$1"
    local description="$2"
    
    echo "🔍 Updating $description..."
    
    # Find and update files
    find . -name "$file_pattern" -type f ! -path "./.git/*" ! -path "./node_modules/*" -exec grep -l "$OLD_REPO\|$OLD_FULL\|$OLD_BADGE_REPO" {} \; 2>/dev/null | while read -r file; do
        echo "  📝 Updating: $file"
        
        # Create temporary file for safe replacement
        temp_file=$(mktemp)
        
        # Perform replacements
        sed -e "s|$OLD_REPO|$NEW_REPO|g" \
            -e "s|$OLD_FULL|$NEW_FULL|g" \
            -e "s|$OLD_BADGE_REPO|$NEW_BADGE_REPO|g" \
            "$file" > "$temp_file"
            
        # Check if file was actually changed
        if ! cmp -s "$file" "$temp_file"; then
            mv "$temp_file" "$file"
            echo "    ✅ Updated successfully"
        else
            rm "$temp_file"
            echo "    ℹ️  No changes needed"
        fi
    done
}

# Function to update specific patterns in files
update_specific_patterns() {
    echo "🎯 Updating specific patterns..."
    
    # Update OIDC patterns in AWS configurations
    find . -name "*.json" -type f -exec grep -l "token.actions.githubusercontent.com.*$OLD_FULL" {} \; 2>/dev/null | while read -r file; do
        echo "  🔐 Updating OIDC patterns in: $file"
        sed -i "s|token.actions.githubusercontent.com:repository.*$OLD_FULL|token.actions.githubusercontent.com:repository": "$NEW_FULL"|g" "$file"
        sed -i "s|repo:$OLD_FULL:|repo:$NEW_FULL:|g" "$file"
    done
    
    # Update S3 bucket paths that might include repository name
    find . -name "*.yml" -o -name "*.yaml" -o -name "*.sh" | xargs grep -l "s3://.*$OLD_REPO" 2>/dev/null | while read -r file; do
        echo "  🪣 Updating S3 paths in: $file"
        sed -i "s|s3://\([^/]*\)/$OLD_FULL/|s3://\1/$NEW_FULL/|g" "$file"
        sed -i "s|s3://\([^/]*\)/$OLD_REPO/|s3://\1/$NEW_REPO/|g" "$file"
    done
    
    # Update GitHub URLs and clone commands
    find . -type f \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" \) | xargs grep -l "github.com.*$OLD_FULL\|github.com.*$OLD_REPO" 2>/dev/null | while read -r file; do
        echo "  🔗 Updating GitHub URLs in: $file"
        sed -i "s|github.com/$OLD_FULL|github.com/$NEW_FULL|g" "$file"
        sed -i "s|github.com/[^/]*/BeaconAgileHub-security-CI-CDpipelines|github.com/$NEW_FULL|g" "$file"
    done
}

echo "🚀 STARTING REPOSITORY NAME UPDATE PROCESS"
echo ""

# 1. Update GitHub Actions workflow files
echo "1️⃣ UPDATING GITHUB ACTIONS WORKFLOWS"
update_repository_references "*.yml" "GitHub Actions workflow files"
update_repository_references "*.yaml" "YAML configuration files"
echo ""

# 2. Update documentation
echo "2️⃣ UPDATING DOCUMENTATION"
update_repository_references "*.md" "Markdown documentation"
update_repository_references "*.rst" "ReStructuredText documentation"
update_repository_references "*.txt" "Text documentation"
echo ""

# 3. Update configuration files
echo "3️⃣ UPDATING CONFIGURATION FILES"
update_repository_references "*.json" "JSON configuration files"
update_repository_references "*.toml" "TOML configuration files"
update_repository_references "*.ini" "INI configuration files"
echo ""

# 4. Update scripts and automation
echo "4️⃣ UPDATING SCRIPTS AND AUTOMATION"
update_repository_references "*.sh" "Shell scripts"
update_repository_references "*.py" "Python scripts"
update_repository_references "*.js" "JavaScript files"
update_repository_references "*.ts" "TypeScript files"
echo ""

# 5. Update Terraform and infrastructure files
echo "5️⃣ UPDATING INFRASTRUCTURE FILES"
update_repository_references "*.tf" "Terraform files"
update_repository_references "*.tfvars" "Terraform variable files"
update_repository_references "*.hcl" "HCL configuration files"
echo ""

# 6. Update Docker and container files
echo "6️⃣ UPDATING CONTAINER FILES"
update_repository_references "Dockerfile*" "Docker files"
update_repository_references "docker-compose*.yml" "Docker Compose files"
update_repository_references "docker-compose*.yaml" "Docker Compose YAML files"
echo ""

# 7. Update Kubernetes manifests
echo "7️⃣ UPDATING KUBERNETES MANIFESTS"
find . -path "./kubernetes/*" -name "*.yml" -o -path "./kubernetes/*" -name "*.yaml" -o -path "./k8s/*" -name "*.yml" -o -path "./k8s/*" -name "*.yaml" | while read -r file; do
    if grep -q "$OLD_REPO\|$OLD_FULL" "$file" 2>/dev/null; then
        echo "  📦 Updating Kubernetes manifest: $file"
        sed -i "s|$OLD_REPO|$NEW_REPO|g" "$file"
        sed -i "s|$OLD_FULL|$NEW_FULL|g" "$file"
    fi
done
echo ""

# 8. Update EDA and Ansible configurations
echo "8️⃣ UPDATING EDA AND ANSIBLE CONFIGURATIONS"
find . -path "./ansible-eda/*" -name "*.yml" -o -path "./ansible-eda/*" -name "*.yaml" | while read -r file; do
    if grep -q "$OLD_REPO\|$OLD_FULL" "$file" 2>/dev/null; then
        echo "  🤖 Updating EDA configuration: $file"
        sed -i "s|$OLD_REPO|$NEW_REPO|g" "$file"
        sed -i "s|$OLD_FULL|$NEW_FULL|g" "$file"
        # Update repository field in EDA rules
        sed -i 's|repository: "'$OLD_FULL'"|repository: "'$NEW_FULL'"|g' "$file"
    fi
done
echo ""

# 9. Update specific patterns
echo "9️⃣ UPDATING SPECIFIC PATTERNS"
update_specific_patterns
echo ""

# 10. Verify changes
echo "🔍 VERIFICATION PHASE"
echo "==================="
echo ""

echo "📊 Changes Summary:"
echo "  Modified files with old repository name:"
grep -r "$OLD_REPO" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | wc -l | xargs echo "    Files with old short name:"
grep -r "$OLD_FULL" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | wc -l | xargs echo "    Files with old full path:"
grep -r "$OLD_BADGE_REPO" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | wc -l | xargs echo "    Files with old badge references:"

echo ""
echo "🎯 Remaining references (should be minimal):"
echo "📝 Files still containing old repository name:"
grep -r "$OLD_REPO" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | head -5 || echo "  ✅ No remaining short name references found"

echo ""
echo "📝 Files still containing old full path:"
grep -r "$OLD_FULL" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | head -5 || echo "  ✅ No remaining full path references found"

echo ""
echo "📝 Files still containing old badge references:"
grep -r "$OLD_BADGE_REPO" . --exclude-dir=.git --exclude="*.log" --exclude="repository-name-update.sh" 2>/dev/null | head -5 || echo "  ✅ No remaining badge references found"

# 11. Generate summary report
echo ""
echo "📋 GENERATING SUMMARY REPORT"
echo "============================"

cat > repository-name-change-report.md << EOF
# Repository Name Change Report

**Date**: $(date)
**From**: $OLD_FULL
**To**: $NEW_FULL

## Changes Made

### Files Updated
- GitHub Actions workflows (*.yml, *.yaml)
- Documentation files (*.md, *.rst, *.txt)
- Configuration files (*.json, *.toml, *.ini)
- Scripts and automation (*.sh, *.py, *.js, *.ts)
- Infrastructure files (*.tf, *.tfvars, *.hcl)
- Container files (Dockerfile*, docker-compose*)
- Kubernetes manifests
- EDA and Ansible configurations

### Specific Updates
- OIDC trust policy references
- S3 bucket path references
- GitHub URLs and clone commands
- Repository badges and shields
- Cross-repository workflow references

### Critical Components Updated
- AWS OIDC authentication patterns
- GitHub Actions workflow calls
- Documentation and README files
- EDA webhook configurations
- Infrastructure as Code references

## Validation Required

### AWS Configuration
- [ ] Update OIDC trust policy in AWS IAM
- [ ] Verify S3 bucket access patterns
- [ ] Test AWS service integrations

### GitHub Integration
- [ ] Validate workflow executions
- [ ] Test cross-repository calls
- [ ] Verify badge display

### EDA Integration
- [ ] Test webhook endpoints
- [ ] Verify event processing
- [ ] Validate rulebook execution

## Next Steps
1. Review and commit changes
2. Update AWS OIDC trust policy
3. Test all integrations
4. Update external references
5. Notify team members

EOF

echo "✅ REPOSITORY NAME UPDATE COMPLETED!"
echo ""
echo "📋 Summary Report: repository-name-change-report.md"
echo "🔧 Next Steps:"
echo "  1. Review the changes: git diff"
echo "  2. Commit the changes: git add . && git commit -m 'Update repository name references'"
echo "  3. Update AWS OIDC trust policy"
echo "  4. Test all integrations"
echo "  5. Push to target branches"
echo ""
echo "⚠️  IMPORTANT: Update AWS OIDC trust policy before running workflows!"
echo "🚀 Repository name change process completed successfully!"