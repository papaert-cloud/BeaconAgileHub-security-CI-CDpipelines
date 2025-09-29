"""
Comprehensive security compliance tests for DevSecOps pipeline
"""
import pytest
import os
import json
from pathlib import Path
import yaml

class TestSecurityCompliance:
    
    def test_terraform_files_exist(self):
        """Verify Terraform infrastructure files exist"""
        terraform_files = list(Path(".").glob("**/*.tf"))
        assert len(terraform_files) > 0, "No Terraform files found"
        
        # Check for required modules
        required_modules = ["oidc-github"]
        for module in required_modules:
            module_path = Path("modules") / module
            if module_path.exists():
                assert (module_path / "main.tf").exists(), f"Missing main.tf in {module}"
    
    def test_workflow_security_configuration(self):
        """Verify workflows have proper security configuration"""
        workflows_dir = Path(".github/workflows")
        assert workflows_dir.exists(), "Workflows directory missing"
        
        yml_files = list(workflows_dir.glob("*.yml")) + list(workflows_dir.glob("*.yaml"))
        assert len(yml_files) > 0, "No workflow files found"
        
        security_workflows = []
        for yml_file in yml_files:
            try:
                with open(yml_file, 'r') as f:
                    content = yaml.safe_load(f)
                    
                # Check for security-related jobs or steps
                if 'jobs' in content:
                    for job_name, job_config in content['jobs'].items():
                        if any(keyword in job_name.lower() for keyword in ['security', 'scan', 'kics', 'checkov']):
                            security_workflows.append(yml_file.name)
                            break
            except yaml.YAMLError:
                pytest.fail(f"Invalid YAML syntax in {yml_file}")
        
        assert len(security_workflows) > 0, "No security scanning workflows found"
    
    def test_required_directories_exist(self):
        """Test that required DevSecOps directory structure exists"""
        required_dirs = [
            ".github",
            ".github/workflows", 
            "tests"
        ]
        
        for dir_path in required_dirs:
            assert Path(dir_path).exists(), f"Required directory {dir_path} missing"
    
    def test_security_tools_configuration(self):
        """Verify security tools are properly configured"""
        # Check for security tool configuration files
        security_configs = [
            ".kics-config.json",
            ".checkov.yml", 
            "trivy.yaml"
        ]
        
        # At least one security config should exist or be referenced in workflows
        config_found = any(Path(config).exists() for config in security_configs)
        
        # If no config files, check workflows for inline config
        if not config_found:
            workflows_dir = Path(".github/workflows")
            if workflows_dir.exists():
                for yml_file in workflows_dir.glob("*.yml"):
                    content = yml_file.read_text()
                    if any(tool in content.lower() for tool in ['kics', 'checkov', 'trivy', 'terrascan']):
                        config_found = True
                        break
        
        assert config_found, "No security tool configuration found"

if __name__ == "__main__":
    pytest.main([__file__, "-v"])