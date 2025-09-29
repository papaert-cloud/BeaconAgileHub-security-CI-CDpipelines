#!/usr/bin/env python3
"""
Aggressive YAML Line Length Fixer
Breaks all lines > 80 characters using YAML folding and proper indentation
"""
import re
from pathlib import Path

def aggressively_fix_line_lengths(content):
    """Break all lines > 80 chars using various YAML techniques"""
    lines = content.split('\n')
    fixed_lines = []
    issues_fixed = 0
    
    for i, line in enumerate(lines):
        original_line = line
        
        # Remove trailing whitespace first
        line = line.rstrip()
        
        # If line is <= 80 chars, keep as-is
        if len(line) <= 80:
            fixed_lines.append(line)
            continue
            
        # Skip comment lines and lines with GitHub expressions
        if line.strip().startswith('#') or ('${{' in line and '}}' in line):
            fixed_lines.append(line)
            continue
            
        # Get indentation
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # Handle different line patterns
        fixed = False
        
        # Pattern 1: Key-value pairs
        if ': ' in line and not line.lstrip().startswith('- '):
            colon_pos = line.find(': ')
            if colon_pos < 60:  # Reasonable key length
                key = line[:colon_pos]
                value = line[colon_pos + 2:]
                
                # Use YAML folded style for long values
                if len(value) > 30:
                    fixed_lines.append(f"{key}: >")
                    fixed_lines.append(f"{indent_str}  {value}")
                    issues_fixed += 1
                    fixed = True
        
        # Pattern 2: List items
        elif line.lstrip().startswith('- '):
            match = re.match(r'^(\s*- )(.+)$', line)
            if match:
                list_marker, content = match.groups()
                if ': ' in content:
                    # List item with key-value
                    colon_pos = content.find(': ')
                    key_part = content[:colon_pos + 1]
                    value_part = content[colon_pos + 2:]
                    
                    if len(value_part) > 30:
                        fixed_lines.append(f"{list_marker}{key_part}")
                        fixed_lines.append(f"{' ' * len(list_marker)}  {value_part}")
                        issues_fixed += 1
                        fixed = True
                else:
                    # Simple list item, break at word boundaries
                    words = content.split()
                    current_line = list_marker + words[0]
                    continuation_indent = ' ' * len(list_marker)
                    
                    for word in words[1:]:
                        if len(current_line + ' ' + word) <= 80:
                            current_line += ' ' + word
                        else:
                            fixed_lines.append(current_line)
                            current_line = continuation_indent + word
                            
                    fixed_lines.append(current_line)
                    issues_fixed += 1
                    fixed = True
        
        # Pattern 3: Environment variables or parameters
        elif re.match(r'^\s+[A-Z_][A-Z0-9_]*:\s+.+', line):
            match = re.match(r'^(\s+)([A-Z_][A-Z0-9_]*:)\s+(.+)$', line)
            if match:
                spaces, var_name, value = match.groups()
                fixed_lines.append(f"{spaces}{var_name} >")
                fixed_lines.append(f"{spaces}  {value}")
                issues_fixed += 1
                fixed = True
        
        # Pattern 4: URLs and long strings
        elif 'http' in line or 'arn:aws:' in line:
            # Try to break at logical points
            if ': ' in line:
                colon_pos = line.find(': ')
                key = line[:colon_pos]
                value = line[colon_pos + 2:]
                
                if '://' in value or 'arn:aws:' in value:
                    fixed_lines.append(f"{key}: >")
                    fixed_lines.append(f"{indent_str}  {value}")
                    issues_fixed += 1
                    fixed = True
        
        # Pattern 5: Bash commands or run statements
        elif 'run:' in line:
            run_pos = line.find('run:')
            if run_pos >= 0:
                prefix = line[:run_pos]
                run_content = line[run_pos + 4:].strip()
                
                if len(run_content) > 40:
                    fixed_lines.append(f"{prefix}run: >")
                    fixed_lines.append(f"{indent_str}  {run_content}")
                    issues_fixed += 1
                    fixed = True
        
        # Fallback: Break at word boundaries
        if not fixed and ' ' in line and len(line) > 80:
            # Find a good breaking point around position 70-80
            break_pos = -1
            for pos in range(70, min(80, len(line))):
                if line[pos] == ' ':
                    break_pos = pos
                    
            if break_pos > 0:
                first_part = line[:break_pos]
                second_part = line[break_pos + 1:]
                fixed_lines.append(first_part)
                fixed_lines.append(f"{indent_str}  {second_part}")
                issues_fixed += 1
                fixed = True
        
        # If still not fixed, just add it as-is (some lines can't be broken)
        if not fixed:
            fixed_lines.append(line)
    
    result = '\n'.join(fixed_lines)
    if not result.endswith('\n'):
        result += '\n'
        
    return result, issues_fixed

def main():
    """Aggressively fix line length issues in all workflow files"""
    workflows_dir = Path('.github/workflows')
    
    if not workflows_dir.exists():
        print(f"❌ Directory {workflows_dir} not found!")
        return 1
    
    yaml_files = list(workflows_dir.glob('*.yml'))
    
    total_fixes = 0
    files_processed = 0
    
    print("⚡ Aggressively fixing line length violations...")
    print()
    
    for yaml_file in sorted(yaml_files):
        print(f"🔧 {yaml_file.name}")
        
        try:
            with open(yaml_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            fixed_content, fixes = aggressively_fix_line_lengths(content)
            
            if fixes > 0:
                with open(yaml_file, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                print(f"   ✅ Broke {fixes} long lines")
                total_fixes += fixes
                files_processed += 1
            else:
                print(f"   ℹ️  No long lines to break")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print()
    print(f"⚡ Aggressive Fix Summary:")
    print(f"   Files processed: {files_processed}")
    print(f"   Lines broken: {total_fixes}")
    
    if total_fixes > 0:
        print()
        print("💡 Next steps:")
        print("   git add .github/workflows/")
        print(f"   git commit -m 'fix: break {total_fixes} long lines for YAML compliance'")
    
    return 0

if __name__ == '__main__':
    exit(main())