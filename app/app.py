#!/usr/bin/env python3
"""
Secure Flask Application for DevSecOps Pipeline Demo
Implements ICS security principles in cloud-native context
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from werkzeug.middleware.proxy_fix import ProxyFix
import boto3
from botocore.exceptions import ClientError

# Configure secure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app with security headers
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

# Security headers middleware
@app.after_request
def add_security_headers(response):
    """Add security headers to all responses"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    return response

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for container orchestration"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': os.getenv('APP_VERSION', '1.0.0')
    }), 200

# SBOM information endpoint
@app.route('/sbom', methods=['GET'])
def get_sbom_info():
    """Return SBOM information for supply chain transparency"""
    try:
        # In production, this would fetch from S3 or artifact registry
        sbom_info = {
            'format': 'CycloneDX',
            'version': '1.5',
            'generated': datetime.utcnow().isoformat(),
            'components': [
                {
                    'name': 'flask',
                    'version': '2.3.3',
                    'type': 'library'
                },
                {
                    'name': 'boto3',
                    'version': '1.29.0',
                    'type': 'library'
                }
            ],
            'vulnerabilities_scanned': True,
            'last_scan': datetime.utcnow().isoformat()
        }
        
        logger.info("SBOM information requested")
        return jsonify(sbom_info), 200
        
    except Exception as e:
        logger.error(f"Error retrieving SBOM info: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Security metrics endpoint
@app.route('/security/metrics', methods=['GET'])
def security_metrics():
    """Return security metrics for monitoring"""
    try:
        # Simulate security metrics collection
        metrics = {
            'security_scan_status': 'passed',
            'vulnerability_count': 0,
            'last_security_scan': datetime.utcnow().isoformat(),
            'compliance_status': {
                'slsa_level': 3,
                'cis_benchmark': 'passed',
                'ics_security': 'compliant'
            },
            'runtime_protection': {
                'falco_alerts': 0,
                'network_policies': 'enforced',
                'pod_security': 'restricted'
            }
        }
        
        logger.info("Security metrics requested")
        return jsonify(metrics), 200
        
    except Exception as e:
        logger.error(f"Error retrieving security metrics: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# AWS Security Hub integration
@app.route('/security/findings', methods=['POST'])
def report_security_finding():
    """Report security findings to AWS Security Hub"""
    try:
        if not request.is_json:
            return jsonify({'error': 'Content-Type must be application/json'}), 400
            
        finding_data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'description', 'severity']
        if not all(field in finding_data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # In production, send to AWS Security Hub
        logger.info(f"Security finding reported: {finding_data['title']}")
        
        return jsonify({
            'status': 'accepted',
            'finding_id': f"finding-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        }), 202
        
    except Exception as e:
        logger.error(f"Error reporting security finding: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ICS security status endpoint
@app.route('/ics/status', methods=['GET'])
def ics_security_status():
    """Return ICS security compliance status"""
    try:
        status = {
            'network_security': {
                'segmentation': 'enforced',
                'monitoring': 'active',
                'intrusion_detection': 'enabled'
            },
            'endpoint_security': {
                'antivirus': 'updated',
                'patch_management': 'current',
                'access_control': 'enforced'
            },
            'application_security': {
                'secure_coding': 'validated',
                'vulnerability_scanning': 'passed',
                'third_party_risk': 'assessed'
            },
            'database_security': {
                'encryption_at_rest': 'enabled',
                'encryption_in_transit': 'enabled',
                'access_monitoring': 'active'
            },
            'compliance_frameworks': {
                'nerc_cip': 'compliant',
                'iec_62443': 'level_2',
                'nist_800_82': 'implemented'
            }
        }
        
        logger.info("ICS security status requested")
        return jsonify(status), 200
        
    except Exception as e:
        logger.error(f"Error retrieving ICS status: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Security: Disable debug mode in production
    debug_mode = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    # Security: Bind to localhost only in development
    host = '0.0.0.0' if os.getenv('FLASK_ENV') == 'production' else '127.0.0.1'
    
    logger.info(f"Starting application on {host}:8080")
    app.run(host=host, port=8080, debug=debug_mode)