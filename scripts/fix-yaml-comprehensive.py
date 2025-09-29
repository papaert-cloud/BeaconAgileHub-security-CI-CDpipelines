#!/usr/bin/env python3
"""
Comprehensive YAML lint fixer for GitHub Actions workflows.
Addresses all common YAML lint issues:
- Missing document start markers (---)
- Line length issues (80 char limit)
- Trailing spaces
- Bracket spacing issues
- Truthy values (use true/false)
"""

import os
import re
import yaml
from pathlib import Path

def fix_yaml_file(file_path):
    """Fix YAML lint issues in a single file."""
    print(f"Processing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    
    # Add document start marker if missing
    if not content.strip().startswith('---'):
        fixed_lines.append('---')
    
    for i, line in enumerate(lines):
        # Skip if already has document marker
        if i == 0 and line.strip() == '---':
            fixed_lines.append(line)
            continue
            
        # Remove trailing spaces
        line = line.rstrip()
        
        # Fix bracket spacing: [ ] -> []
        line = re.sub(r'\[\s+\]', '[]', line)
        
        # Fix truthy values
        truthy_map = {"on": "true", "off": "false", "yes": "true", "no": "false"}
        def fix_truthy(match):
            return f': {truthy_map.get(match.group(1).lower(), match.group(1).lower())}'
        line = re.sub(r':\s+(on|off|yes|no|On|Off|Yes|No|ON|OFF|YES|NO)\s*$', fix_truthy, line)
        
        # Handle long lines (80+ chars) - break at logical points
        if len(line) > 80 and ':' in line and not line.strip().startswith('#'):
            # For YAML values, try to break at logical points
            if ' - ' in line or 'run: |' in line:
                # Don't break run blocks or list items
                fixed_lines.append(line)
            elif line.count(':') == 1 and '|' not in line and '>' not in line:
                # Simple key: value pairs - use folded scalar
                key, value = line.split(':', 1)
                value = value.strip()
                if len(value) > 60:  # Only fold if value is long
                    indent = len(key) - len(key.lstrip())
                    fixed_lines.append(f"{key}: >")
                    fixed_lines.append(f"{' ' * (indent + 2)}{value}")
                else:
                    fixed_lines.append(line)
            else:
                fixed_lines.append(line)
        else:
            fixed_lines.append(line)
    
    # Join lines and ensure single trailing newline
    fixed_content = '\n'.join(fixed_lines)
    if not fixed_content.endswith('\n'):
        fixed_content += '\n'
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"Fixed: {file_path}")

def main():
    """Fix all YAML files in workflows directory."""
    workflows_dir = Path('.github/workflows')
    
    if not workflows_dir.exists():
        print("No .github/workflows directory found")
        return
    
    yaml_files = list(workflows_dir.glob('*.yml')) + list(workflows_dir.glob('*.yaml'))
    
    print(f"Found {len(yaml_files)} YAML files to process")
    
    for yaml_file in yaml_files:
        try:
            fix_yaml_file(yaml_file)
        except Exception as e:
            print(f"Error processing {yaml_file}: {e}")
    
    print("YAML lint fixes completed!")

if __name__ == '__main__':
    main()