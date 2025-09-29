#!/usr/bin/env python3
"""
Advanced YAML Lint Fixer for GitHub Actions Workflows
Fixes common yamllint violations while preserving bash syntax and functionality
"""
import re
from pathlib import Path

def fix_yaml_content(content):
    """Fix various YAML lint issues while preserving functionality"""
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        original_line = line
        
        # Add document start marker to first line if missing
        if i == 0 and line.strip() and not line.strip().startswith('---'):
            fixed_lines.append('---')
            fixed_lines.append(line)
            continue
            
        # Remove trailing whitespace
        line = line.rstrip()
        
        # Fix truthy values - quote 'on:' values that are not proper booleans
        if re.match(r'^(\s*)on:\s*$', line):
            # This is a standalone 'on:' key, next lines will have the trigger values
            fixed_lines.append(line)
            continue
        elif re.match(r'^(\s*)on:\s+(.+)$', line):
            # This is an inline 'on: value' format - quote the value if needed
            match = re.match(r'^(\s*)on:\s+(.+)$', line)
            if match:
                indent, value = match.groups()
                # Only quote if it's not already quoted and not a complex structure
                if not (value.startswith('"') or value.startswith("'") or value.startswith('[')):
                    if value in ['push', 'pull_request', 'schedule', 'workflow_dispatch']:
                        line = f'{indent}on: "{value}"'
        
        # Fix comment spacing - ensure at least 2 spaces before comments
        if '#' in line and not line.strip().startswith('#'):
            # Find the comment position
            comment_pos = line.find('#')
            before_comment = line[:comment_pos]
            comment = line[comment_pos:]
            
            # Only fix if there's less than 2 spaces before #
            if before_comment.endswith(' '):
                spaces = 0
                for j in range(len(before_comment) - 1, -1, -1):
                    if before_comment[j] == ' ':
                        spaces += 1
                    else:
                        break
                        
                if spaces == 1:
                    line = before_comment + ' ' + comment
        
        # Handle line length issues - break long lines intelligently
        if len(line) > 80 and not line.strip().startswith('#'):
            # Skip if it contains bash expressions we shouldn't break
            if '${{' in line and '}}' in line:
                # GitHub Actions expressions - be very careful
                fixed_lines.append(line)
                continue
                
            if '|' in line and ('bash' in line or 'shell' in line):
                # Shell commands - don't break
                fixed_lines.append(line)
                continue
                
            # Try to find a good breaking point for YAML key-value pairs
            if ': ' in line and not line.lstrip().startswith('- '):
                colon_pos = line.find(': ')
                if colon_pos > 0 and colon_pos < 60:  # reasonable key length
                    key = line[:colon_pos + 1]
                    value = line[colon_pos + 2:]
                    
                    if len(value) > 40 and ' ' in value:  # long value worth breaking
                        # Try to break at word boundaries
                        words = value.split()
                        indent = len(line) - len(line.lstrip())
                        current_line = key + ' ' + words[0]
                        continuation_indent = ' ' * (indent + 2)
                        
                        for word in words[1:]:
                            if len(current_line + ' ' + word) <= 80:
                                current_line += ' ' + word
                            else:
                                fixed_lines.append(current_line)
                                current_line = continuation_indent + word
                                
                        if current_line.strip():
                            fixed_lines.append(current_line)
                        continue
            
            # For lists that are too long
            if line.lstrip().startswith('- ') and len(line) > 80:
                # Try to break list items
                match = re.match(r'^(\s*- )(.+)$', line)
                if match:
                    list_prefix, list_content = match.groups()
                    if ': ' in list_content:
                        # List item with key-value, try to break after key
                        key_val_match = re.match(r'^([^:]+: )(.+)$', list_content)
                        if key_val_match and len(key_val_match.group(2)) > 40:
                            key_part, val_part = key_val_match.groups()
                            if ' ' in val_part:
                                words = val_part.split()
                                current_line = list_prefix + key_part + words[0]
                                continuation_indent = ' ' * len(list_prefix) + ' '
                                
                                for word in words[1:]:
                                    if len(current_line + ' ' + word) <= 80:
                                        current_line += ' ' + word
                                    else:
                                        fixed_lines.append(current_line)
                                        current_line = continuation_indent + word
                                        
                                if current_line.strip():
                                    fixed_lines.append(current_line)
                                continue
        
        # Fix bracket spacing in arrays
        if '[' in line and ']' in line and not line.strip().startswith('#'):
            line = re.sub(r'\[\s*([^]]+)\s*\]', lambda m: '[' + ', '.join(x.strip() for x in m.group(1).split(',')) + ']', line)
        
        fixed_lines.append(line)
    
    # Ensure file ends with single newline
    result = '\n'.join(fixed_lines)
    if not result.endswith('\n'):
        result += '\n'
    elif result.endswith('\n\n'):
        result = result.rstrip('\n') + '\n'
        
    return result

import os
import re
import glob
from pathlib import Path

def fix_yaml_file(file_path):
    """Fix common YAML lint issues in a single file"""
    print(f"Fixing: {file_path}")
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    fixed_lines = []
    changes_made = []
    
    for i, line in enumerate(lines):
        original_line = line
        
        # Remove trailing spaces
        line = line.rstrip() + '\n'
        if line != original_line:
            changes_made.append(f"Line {i+1}: Removed trailing spaces")
        
        # Fix bracket spacing: [ ] -> [] (but NOT in bash conditionals)
        # Only fix YAML arrays, not bash test conditions
        if not re.search(r'if \[', line) and not re.search(r'elif \[', line):
            line = re.sub(r'\[\s+([^\]]*)\s+\]', r'[\1]', line)
        
        # Fix truthy values in common contexts
        # on: push: -> on: true (but we need to be more specific)
        if re.match(r'^\s*on:\s*$', line):
            # This is fine, next line will have the actual trigger
            pass
        elif re.match(r'^\s*(push|pull_request|workflow_dispatch|schedule):\s*$', line):
            # These are fine as-is
            pass
        
        # Fix line length by using YAML folding for long lines
        if len(line.rstrip()) > 80:
            # Look for common patterns we can fold
            
            # Long role-to-assume lines
            if 'role-to-assume:' in line and 'arn:aws:iam::' in line:
                indent = len(line) - len(line.lstrip())
                spaces = ' ' * indent
                if '>' not in line:  # Don't double-fold
                    line = f"{spaces}role-to-assume: >\n{spaces}  {line.split('role-to-assume:')[1].strip()}\n"
                    changes_made.append(f"Line {i+1}: Folded long role-to-assume line")
            
            # Long curl commands
            elif 'curl -' in line and len(line.rstrip()) > 80:
                if '\\' not in line:  # Don't double-escape
                    indent = len(line) - len(line.lstrip())
                    spaces = ' ' * indent
                    # Split at logical points
                    line_content = line.strip()
                    if 'curl -sSfL' in line_content:
                        parts = line_content.split('curl -sSfL ')
                        if len(parts) > 1:
                            line = f"{spaces}curl -sSfL \\\n{spaces}  {parts[1]}\n"
                            changes_made.append(f"Line {i+1}: Split long curl command")
            
            # Long echo/run commands
            elif line.strip().startswith('run:') and len(line.rstrip()) > 80:
                # Use YAML literal block for long run commands
                indent = len(line) - len(line.lstrip())
                spaces = ' ' * indent
                if '|' not in line and '>' not in line:
                    content = line.split('run:')[1].strip()
                    line = f"{spaces}run: >\n{spaces}  {content}\n"
                    changes_made.append(f"Line {i+1}: Folded long run command")
        
        fixed_lines.append(line)
    
    # Add document start marker if missing
    if fixed_lines and not fixed_lines[0].startswith('---'):
        fixed_lines.insert(0, '---\n')
        changes_made.append("Added document start marker (---)")
    
    # Ensure final newline
    if fixed_lines and not fixed_lines[-1].endswith('\n'):
        fixed_lines[-1] += '\n'
        changes_made.append("Added final newline")
    
    # Write back the fixed content
    with open(file_path, 'w') as f:
        f.writelines(fixed_lines)
    
    if changes_made:
        print(f"  Changes made: {len(changes_made)}")
        for change in changes_made[:5]:  # Show first 5 changes
            print(f"    - {change}")
        if len(changes_made) > 5:
            print(f"    ... and {len(changes_made) - 5} more")
    else:
        print("  No changes needed")
    
    return len(changes_made)

def main():
    """Fix YAML lint issues in all workflow files"""
    workflow_dir = Path(".github/workflows")
    
    if not workflow_dir.exists():
        print("Error: .github/workflows directory not found")
        return 1
    
    yaml_files = list(workflow_dir.glob("*.yml")) + list(workflow_dir.glob("*.yaml"))
    
    if not yaml_files:
        print("No YAML files found in .github/workflows/")
        return 1
    
    print(f"Found {len(yaml_files)} YAML files to fix")
    
    total_changes = 0
    for yaml_file in sorted(yaml_files):
        changes = fix_yaml_file(yaml_file)
        total_changes += changes
    
    print(f"\nSummary: Fixed {total_changes} total issues across {len(yaml_files)} files")
    
    if total_changes > 0:
        print("\nRecommended next steps:")
        print("1. Review the changes: git diff")
        print("2. Test a workflow: gh workflow run <workflow-name>")
        print("3. Commit the fixes: git add -A && git commit -m 'fix: automated YAML lint corrections'")
    
    return 0

if __name__ == "__main__":
    exit(main())