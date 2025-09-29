#!/usr/bin/env python3
"""
Comprehensive YAML Lint Fixer v2.0 for GitHub Actions Workflows
Fixes yamllint violations while preserving functionality
"""
import re
from pathlib import Path

def fix_yaml_content(content):
    """Fix various YAML lint issues comprehensively"""
    lines = content.split('\n')
    fixed_lines = []
    issues_fixed = 0
    
    for i, line in enumerate(lines):
        original_line = line
        
        # Add document start marker to first line if missing
        if i == 0 and line.strip() and not line.strip().startswith('---'):
            fixed_lines.append('---')
            issues_fixed += 1
            
        # Remove trailing whitespace
        line = line.rstrip()
        if line != original_line.rstrip():
            issues_fixed += 1
            
        # Fix truthy values - specifically for 'on:' triggers
        truthy_match = re.match(r'^(\s*)(on|push|pull_request|schedule|workflow_dispatch):\s*$', line)
        if truthy_match:
            indent, key = truthy_match.groups()
            # These standalone keys are fine, it's inline values that need quotes
            fixed_lines.append(line)
            continue
            
        # Fix comment spacing - ensure at least 2 spaces before comments
        if '#' in line and not line.strip().startswith('#'):
            comment_pos = line.find('#')
            before_comment = line[:comment_pos]
            comment = line[comment_pos:]
            
            # Check if there's exactly 1 space before the comment
            if before_comment.endswith(' ') and not before_comment.endswith('  '):
                # Count trailing spaces
                spaces = 0
                for j in range(len(before_comment) - 1, -1, -1):
                    if before_comment[j] == ' ':
                        spaces += 1
                    else:
                        break
                        
                if spaces == 1:
                    line = before_comment + ' ' + comment
                    issues_fixed += 1
        
        # Handle line length issues (> 80 characters)
        if len(line) > 80 and not line.strip().startswith('#'):
            original_line_len = len(line)
            
            # Skip GitHub Actions expressions - too risky to break
            if '${{' in line and '}}' in line:
                fixed_lines.append(line)
                continue
                
            # Skip shell commands with pipes or complex bash
            if any(x in line for x in ['|', '&&', '||', 'bash -c', 'shell:']):
                fixed_lines.append(line)
                continue
                
            # Handle YAML key-value pairs
            if ': ' in line and not line.lstrip().startswith('- '):
                colon_pos = line.find(': ')
                if colon_pos > 0 and colon_pos < 60:
                    key = line[:colon_pos + 1]
                    value = line[colon_pos + 2:]
                    indent = len(line) - len(line.lstrip())
                    
                    # Try different breaking strategies
                    broken = False
                    
                    # Strategy 1: Use YAML folding for very long values
                    if len(value) > 50 and not any(char in value for char in ['${{', '}}', '|', '&']):
                        if ' ' in value and not value.startswith('"'):
                            # Use folded scalar (>)
                            fixed_lines.append(f"{' ' * indent}{key.strip()}: >")
                            fixed_lines.append(f"{' ' * (indent + 2)}{value.strip()}")
                            issues_fixed += 1
                            broken = True
                    
                    # Strategy 2: Break at logical word boundaries
                    if not broken and ' ' in value and len(value) > 40:
                        words = value.split()
                        current_line = key + ' ' + words[0]
                        continuation_indent = ' ' * (indent + 2)
                        
                        remaining_words = []
                        for word in words[1:]:
                            if len(current_line + ' ' + word) <= 80:
                                current_line += ' ' + word
                            else:
                                remaining_words = words[words.index(word):]
                                break
                                
                        if remaining_words:
                            fixed_lines.append(current_line)
                            # Add continuation lines
                            continuation_line = continuation_indent
                            for word in remaining_words:
                                if len(continuation_line + word + ' ') <= 80:
                                    continuation_line += word + ' '
                                else:
                                    if continuation_line.strip():
                                        fixed_lines.append(continuation_line.rstrip())
                                    continuation_line = continuation_indent + word + ' '
                            if continuation_line.strip():
                                fixed_lines.append(continuation_line.rstrip())
                            issues_fixed += 1
                            broken = True
                    
                    if broken:
                        continue
            
            # Handle long list items
            if line.lstrip().startswith('- ') and len(line) > 80:
                match = re.match(r'^(\s*- )(.+)$', line)
                if match:
                    list_prefix, list_content = match.groups()
                    if ': ' in list_content and ' ' in list_content:
                        # Try to break list item with key-value
                        key_val_pos = list_content.find(': ')
                        if key_val_pos > 0:
                            key_part = list_content[:key_val_pos + 1]
                            val_part = list_content[key_val_pos + 2:]
                            
                            if len(val_part) > 30 and ' ' in val_part:
                                # Break the list item
                                fixed_lines.append(list_prefix + key_part)
                                continuation_indent = ' ' * len(list_prefix) + ' '
                                fixed_lines.append(continuation_indent + val_part)
                                issues_fixed += 1
                                continue
        
        fixed_lines.append(line)
    
    # Ensure file ends with single newline
    result = '\n'.join(fixed_lines)
    if not result.endswith('\n'):
        result += '\n'
        issues_fixed += 1
    elif result.endswith('\n\n'):
        result = result.rstrip('\n') + '\n'
        issues_fixed += 1
        
    return result, issues_fixed

def main():
    """Main function to fix YAML lint issues in workflows"""
    workflows_dir = Path('.github/workflows')
    
    if not workflows_dir.exists():
        print(f"❌ Directory {workflows_dir} not found!")
        return 1
        
    # Get all YAML files
    yaml_files = list(workflows_dir.glob('*.yml')) + list(workflows_dir.glob('*.yaml'))
    
    if not yaml_files:
        print("❌ No YAML files found in workflows directory")
        return 1
        
    total_fixes = 0
    files_processed = 0
    
    print(f"🔧 Processing {len(yaml_files)} YAML files...")
    print()
    
    for yaml_file in sorted(yaml_files):
        print(f"📝 {yaml_file.name}")
        
        try:
            with open(yaml_file, 'r', encoding='utf-8') as f:
                original_content = f.read()
                
            fixed_content, fixes_count = fix_yaml_content(original_content)
            
            if fixes_count > 0:
                with open(yaml_file, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                    
                print(f"   ✅ Fixed {fixes_count} issues")
                total_fixes += fixes_count
                files_processed += 1
            else:
                print(f"   ℹ️  No fixes needed")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            
    print()
    print(f"🎯 Summary:")
    print(f"   Files with fixes: {files_processed}/{len(yaml_files)}")
    print(f"   Total issues fixed: {total_fixes}")
    
    if total_fixes > 0:
        print()
        print(f"💡 Next steps:")
        print(f"   git add .github/workflows/")
        print(f"   git commit -m 'fix: resolve {total_fixes} additional YAML lint violations'")
        print(f"   gh workflow run yamllint")
    
    return 0

if __name__ == '__main__':
    exit(main())