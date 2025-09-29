#!/usr/bin/env python3
"""
Final Pass YAML Line Fixer
Manually handle the most stubborn long lines
"""
import re
from pathlib import Path

def final_line_fixes(content, filename):
    """Apply final targeted fixes for remaining long lines"""
    lines = content.split('\n')
    fixed_lines = []
    issues_fixed = 0
    
    for i, line in enumerate(lines):
        if len(line) > 80:
            # Handle shell commands with GitHub expressions by using line continuation
            if 'cosign sign' in line or 'curl -' in line or 'docker ' in line:
                # Use shell line continuation
                if '\\' not in line and ' ' in line:
                    # Find a good break point
                    words = line.split()
                    current_line = words[0]
                    indent = len(line) - len(line.lstrip())
                    continuation_indent = ' ' * (indent + 2)
                    
                    for word in words[1:]:
                        if len(current_line + ' ' + word) <= 75:  # Leave room for \
                            current_line += ' ' + word
                        else:
                            current_line += ' \\'
                            fixed_lines.append(current_line)
                            current_line = continuation_indent + word
                            
                    if current_line.strip():
                        fixed_lines.append(current_line)
                    issues_fixed += 1
                    continue
                    
            # Handle long echo statements
            elif 'echo ' in line and len(line) > 80:
                if '\\' not in line:
                    # Break echo statements at logical points
                    echo_pos = line.find('echo ')
                    if echo_pos >= 0:
                        prefix = line[:echo_pos + 5]
                        message = line[echo_pos + 5:]
                        if len(message) > 50 and ' ' in message:
                            # Break the message
                            mid_point = len(message) // 2
                            # Find nearest space to mid point
                            break_pos = message.rfind(' ', 0, mid_point + 20)
                            if break_pos > 0:
                                first_part = message[:break_pos]
                                second_part = message[break_pos + 1:]
                                indent = len(line) - len(line.lstrip())
                                fixed_lines.append(f"{prefix}{first_part} \\")
                                fixed_lines.append(f"{' ' * (indent + 2)}{second_part}")
                                issues_fixed += 1
                                continue
                                
            # Handle long URLs or ARNs by using YAML literal blocks
            elif ('http' in line or 'arn:aws:' in line) and ': ' in line:
                colon_pos = line.find(': ')
                if colon_pos > 0 and colon_pos < 60:
                    key = line[:colon_pos + 1]
                    value = line[colon_pos + 2:]
                    indent = len(line) - len(line.lstrip())
                    
                    fixed_lines.append(f"{' ' * indent}{key.strip()}: >")
                    fixed_lines.append(f"{' ' * (indent + 2)}{value}")
                    issues_fixed += 1
                    continue
                    
            # Handle long run commands differently
            elif line.strip().startswith('run: ') and len(line) > 80:
                # Convert to block scalar
                indent = len(line) - len(line.lstrip())
                run_content = line[line.find('run: ') + 5:]
                fixed_lines.append(f"{' ' * indent}run: >")
                fixed_lines.append(f"{' ' * (indent + 2)}{run_content}")
                issues_fixed += 1
                continue
                
            # Handle environment variables that are too long
            elif re.match(r'^\s+[A-Z_]+: .+', line) and len(line) > 80:
                match = re.match(r'^(\s+)([A-Z_]+): (.+)$', line)
                if match:
                    spaces, var_name, value = match.groups()
                    fixed_lines.append(f"{spaces}{var_name}: >")
                    fixed_lines.append(f"{spaces}  {value}")
                    issues_fixed += 1
                    continue
                    
        fixed_lines.append(line)
    
    result = '\n'.join(fixed_lines)
    return result, issues_fixed

def main():
    """Apply final fixes to remaining long lines"""
    workflows_dir = Path('.github/workflows')
    
    yaml_files = list(workflows_dir.glob('*.yml'))
    
    total_fixes = 0
    
    print("🏁 Final pass: fixing remaining long lines...")
    print()
    
    for yaml_file in sorted(yaml_files):
        with open(yaml_file, 'r') as f:
            content = f.read()
        
        fixed_content, fixes = final_line_fixes(content, yaml_file.name)
        
        if fixes > 0:
            with open(yaml_file, 'w') as f:
                f.write(fixed_content)
            print(f"✅ {yaml_file.name}: Fixed {fixes} lines")
            total_fixes += fixes
    
    print(f"\n🏁 Final pass complete: {total_fixes} lines fixed")
    
    if total_fixes > 0:
        print("\n💡 Test the results:")
        print("   yamllint .github/workflows/ | grep 'line too long' | wc -l")

if __name__ == '__main__':
    main()