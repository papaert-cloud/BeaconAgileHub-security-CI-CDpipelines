#!/bin/bash
# 🛠️ Fix S3 Bucket Issue for Security Scan Results
# Addresses: NoSuchBucket error when uploading KICS results

set -euo pipefail

echo "🛠️ FIXING S3 BUCKET CONFIGURATION FOR SECURITY RESULTS"
echo "======================================================="

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
BUCKET_PREFIX="devsecops"
ACCOUNT_ID="005965605891"

# Required buckets for DevSecOps workflows
REQUIRED_BUCKETS=(
    "devsecops-security-findings"
    "devsecops-sbom-storage"
    "devsecops-compliance-reports"
    "devsecops-artifacts-storage"
)

echo "📊 Configuration:"
echo "  AWS Region: $AWS_REGION"
echo "  Account ID: $ACCOUNT_ID"
echo "  Bucket Prefix: $BUCKET_PREFIX"
echo ""

# Function to create bucket with proper configuration
create_bucket() {
    local bucket_name=$1
    
    echo "🪣 Creating S3 bucket: $bucket_name"
    
    # Create bucket
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$bucket_name" --region "$AWS_REGION"
    else
        aws s3api create-bucket \
            --bucket "$bucket_name" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    # Enable versioning for audit trail
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    
    # Enable default encryption
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    # Add lifecycle policy for cost optimization
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$bucket_name" \
        --lifecycle-configuration '{
            "Rules": [{
                "ID": "DevSecOpsLifecycle",
                "Status": "Enabled",
                "Transitions": [{
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                }, {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                }],
                "Expiration": {
                    "Days": 365
                }
            }]
        }'
    
    echo "✅ Bucket $bucket_name configured with security best practices"
}

# Function to create IAM policy for bucket access
create_bucket_policy() {
    local bucket_name=$1
    
    echo "🔐 Creating bucket policy for: $bucket_name"
    
    cat > "${bucket_name}-policy.json" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GitHubActionsAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${ACCOUNT_ID}:role/GitHubActionsRole"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket_name}",
                "arn:aws:s3:::${bucket_name}/*"
            ]
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy \
        --bucket "$bucket_name" \
        --policy file://"${bucket_name}-policy.json"
        
    rm -f "${bucket_name}-policy.json"
    
    echo "✅ Bucket policy applied for GitHubActionsRole"
}

# Check if we have AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ ERROR: No AWS credentials available"
    echo "💡 SOLUTION: Configure AWS credentials or run from GitHub Actions with OIDC"
    echo ""
    echo "For GitHub Actions OIDC (recommended):"
    echo "  - This script will be called from workflows with proper OIDC authentication"
    echo ""
    echo "For local testing:"
    echo "  aws configure"
    echo "  # OR"
    echo "  export AWS_ACCESS_KEY_ID=..."
    echo "  export AWS_SECRET_ACCESS_KEY=..."
    exit 1
fi

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$ACCOUNT_ID" ]; then
    echo "❌ ERROR: Wrong AWS account"
    echo "  Expected: $ACCOUNT_ID"
    echo "  Current: $CURRENT_ACCOUNT"
    exit 1
fi

echo "✅ AWS credentials verified for account: $CURRENT_ACCOUNT"
echo ""

# Create all required buckets
for bucket in "${REQUIRED_BUCKETS[@]}"; do
    echo "🔍 Checking bucket: $bucket"
    
    if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
        echo "  ✅ Bucket exists: $bucket"
    else
        echo "  📦 Creating bucket: $bucket"
        create_bucket "$bucket"
        create_bucket_policy "$bucket"
    fi
    
    echo ""
done

# Test bucket access with sample file
echo "🧪 Testing S3 bucket access..."
TEST_FILE="/tmp/test-security-scan.json"
cat > "$TEST_FILE" << 'EOF'
{
    "tool": "test",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "summary": "S3 bucket access test",
    "findings": 0
}
EOF

# Upload test file to security findings bucket
aws s3 cp "$TEST_FILE" "s3://devsecops-security-findings/test/bucket-access-test.json"

# Verify upload
if aws s3 ls "s3://devsecops-security-findings/test/bucket-access-test.json" >/dev/null; then
    echo "✅ S3 upload test successful"
    
    # Cleanup test file
    aws s3 rm "s3://devsecops-security-findings/test/bucket-access-test.json"
    rm -f "$TEST_FILE"
else
    echo "❌ S3 upload test failed"
fi

echo ""
echo "🎉 S3 BUCKET CONFIGURATION COMPLETE!"
echo "===================================="
echo ""
echo "✅ Created/Verified Buckets:"
for bucket in "${REQUIRED_BUCKETS[@]}"; do
    echo "  📦 $bucket"
done

echo ""
echo "🔐 Security Features Applied:"
echo "  ✅ Versioning enabled (audit trail)"
echo "  ✅ Default encryption (AES256)"
echo "  ✅ Public access blocked"
echo "  ✅ IAM policy for GitHubActionsRole"
echo "  ✅ Lifecycle policy (cost optimization)"

echo ""
echo "🚀 GitHub Actions can now upload security scan results!"
echo "💡 Re-run your security workflows to test S3 integration"