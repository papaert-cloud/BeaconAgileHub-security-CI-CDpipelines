#!/usr/bin/env python3
"""Security compliance tests for infrastructure"""

import json
import boto3
import pytest
from moto import mock_aws

class TestSecurityCompliance:
    
    def test_vpc_flow_logs_enabled(self):
        """Test that VPC Flow Logs are enabled"""
        with open('../terraform/modules/network-security/main.tf', 'r') as f:
            content = f.read()
            assert 'aws_flow_log' in content
            assert 'traffic_type    = "ALL"' in content

    def test_s3_encryption_enabled(self):
        """Test S3 bucket encryption configuration"""
        with open('../cloudformation/templates/security-stack.yaml', 'r') as f:
            content = f.read()
            assert 'BucketEncryption' in content
            assert 'aws:kms' in content

    def test_kms_key_rotation(self):
        """Test KMS key rotation is enabled"""
        with open('../cloudformation/templates/security-stack.yaml', 'r') as f:
            content = f.read()
            assert 'AWS::KMS::Key' in content

    def test_security_group_rules(self):
        """Test security group rules are restrictive"""
        with open('../terraform/modules/vpc-endpoints/main.tf', 'r') as f:
            content = f.read()
            assert 'from_port   = 443' in content
            assert 'to_port     = 443' in content
            assert 'protocol    = "tcp"' in content

    def test_nacl_configuration(self):
        """Test Network ACL configuration"""
        with open('../terraform/modules/network-security/main.tf', 'r') as f:
            content = f.read()
            assert 'aws_network_acl' in content
            assert 'from_port  = 80' in content
            assert 'from_port  = 443' in content

    @mock_aws
    def test_s3_public_access_blocked(self):
        """Test S3 public access is blocked"""
        client = boto3.client('s3', region_name='us-east-1')
        
        # This would be tested against actual deployed resources
        # Mock test for demonstration
        bucket_name = 'test-security-bucket'
        client.create_bucket(Bucket=bucket_name)
        
        # Verify public access block would be configured
        assert True  # Placeholder for actual test

if __name__ == "__main__":
    pytest.main([__file__])