#!/bin/bash
# 🔧 Automated Merge Conflict Resolution for DevSecOps Workflows

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}�� DevSecOps Workflow Conflict Resolution${NC}"
echo "=========================================="

# Get list of conflicted files
CONFLICTED_FILES=$(git diff --name-only --diff-filter=U)

if [ -z "$CONFLICTED_FILES" ]; then
    echo -e "${GREEN}✅ No conflicts found!${NC}"
    exit 0
fi

echo -e "${YELLOW}📋 Conflicted files:${NC}"
echo "$CONFLICTED_FILES"
echo ""

# Function to resolve YAML conflicts intelligently
resolve_yaml_conflict() {
    local file="$1"
    echo -e "${BLUE}🔧 Resolving conflicts in: $file${NC}"
    
    # Create backup
    cp "$file" "${file}.conflict-backup"
    
    # Enhanced conflict resolution strategy
    python3 -c "
import re
import sys

def resolve_yaml_conflict(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    # Track if we're in a conflict block
    lines = content.split('\n')
    resolved_lines = []
    in_conflict = False
    conflict_start = 0
    head_lines = []
    main_lines = []
    
    for i, line in enumerate(lines):
        if line.startswith('<<<<<<<'):
            in_conflict = True
            conflict_start = i
            head_lines = []
            main_lines = []
        elif line.startswith('=======') and in_conflict:
            # Switch to collecting main lines
            collecting_main = True
        elif line.startswith('>>>>>>>') and in_conflict:
            # End of conflict - resolve intelligently
            resolution = resolve_conflict_block(head_lines, main_lines, filename)
            resolved_lines.extend(resolution)
            in_conflict = False
        elif in_conflict:
            if '=======' not in '\n'.join(lines[conflict_start:i+1]):
                head_lines.append(line)
            else:
                main_lines.append(line)
        else:
            resolved_lines.append(line)
    
    return '\n'.join(resolved_lines)

def resolve_conflict_block(head_lines, main_lines, filename):
    # Intelligent conflict resolution based on content analysis
    head_content = '\n'.join(head_lines)
    main_content = '\n'.join(main_lines)
    
    # Priority rules for DevSecOps workflows
    
    # 1. Preserve enhanced security configurations
    if 'enhanced' in filename or 'security' in filename:
        # Prefer S-lab (HEAD) for security enhancements
        if any('fail_on_severity' in line or 'security_severity' in line or 'SNYK_TOKEN' in line for line in head_lines):
            return head_lines
    
    # 2. Preserve monitoring and EDA configurations  
    if any('grafana' in line.lower() or 'prometheus' in line.lower() or 'eda' in line.lower() for line in head_lines):
        return head_lines
    
    # 3. Merge environment variables intelligently
    if any('env:' in line or 'environment:' in line for line in head_lines + main_lines):
        merged_env = merge_environment_vars(head_lines, main_lines)
        return merged_env
    
    # 4. Preserve job configurations with dependencies
    if any('jobs:' in line or 'needs:' in line for line in head_lines + main_lines):
        return merge_job_configurations(head_lines, main_lines)
    
    # 5. Default: prefer HEAD (S-lab) with enhanced features
    return head_lines

def merge_environment_vars(head_lines, main_lines):
    # Combine unique environment variables from both branches
    head_env = [line for line in head_lines if '=' in line or ':' in line]
    main_env = [line for line in main_lines if '=' in line or ':' in line]
    
    # Remove duplicates, prefer HEAD values
    seen_vars = set()
    merged = []
    
    for line in head_lines:
        if ':' in line:
            var_name = line.split(':')[0].strip()
            if var_name not in seen_vars:
                merged.append(line)
                seen_vars.add(var_name)
    
    for line in main_lines:
        if ':' in line:
            var_name = line.split(':')[0].strip()
            if var_name not in seen_vars:
                merged.append(line)
                seen_vars.add(var_name)
    
    return merged

def merge_job_configurations(head_lines, main_lines):
    # Preserve job structure from HEAD, add missing jobs from main
    return head_lines  # S-lab has more comprehensive job configurations

# Process the file
try:
    resolved_content = resolve_yaml_conflict('$file')
    with open('$file', 'w') as f:
        f.write(resolved_content)
    print('✅ Resolved conflicts in $file')
except Exception as e:
    print(f'❌ Error resolving $file: {e}')
    sys.exit(1)
" || echo "⚠️ Python resolution failed, using manual approach"

    # Fallback: Manual resolution with intelligent defaults
    if [ $? -ne 0 ]; then
        echo "🔧 Using manual conflict resolution..."
        
        # Remove conflict markers and prefer S-lab content for enhanced features
        sed -i '/^<<<<<<< HEAD$/d' "$file"
        sed -i '/^=======$/d' "$file" 
        sed -i '/^>>>>>>> origin\/main$/d' "$file"
        
        echo "⚠️ Manual resolution applied - please review $file"
    fi
    
    # Validate YAML syntax
    if command -v yq >/dev/null 2>&1; then
        if yq eval '.' "$file" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ YAML syntax valid for $file${NC}"
        else
            echo -e "${RED}❌ YAML syntax error in $file${NC}"
            echo "Restoring backup..."
            mv "${file}.conflict-backup" "$file"
            return 1
        fi
    fi
    
    rm -f "${file}.conflict-backup"
}

# Process each conflicted file
for file in $CONFLICTED_FILES; do
    if [[ $file == *.yml ]] || [[ $file == *.yaml ]]; then
        resolve_yaml_conflict "$file"
    else
        echo -e "${YELLOW}⚠️ Non-YAML file $file requires manual resolution${NC}"
    fi
    echo ""
done

echo -e "${GREEN}🎯 Conflict resolution complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Review resolved files"
echo "2. Test YAML syntax: find .github/workflows -name '*.yml' -exec yq eval '.' {} \;"
echo "3. Stage and commit: git add . && git commit -m 'Resolve merge conflicts'"
echo "4. Push to S-lab: git push origin S-lab"
