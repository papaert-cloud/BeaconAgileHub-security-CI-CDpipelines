#!/usr/bin/env bash
set -euo pipefail
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <s3-bucket> [s3-key]"
  exit 2
fi
S3_BUCKET=$1
S3_KEY=${2:-remediate/remediate.zip}
aws s3 cp /tmp/remediate.zip s3://"$S3_BUCKET"/"$S3_KEY" --region ${AWS_REGION:-us-east-1}
echo "Uploaded to s3://$S3_BUCKET/$S3_KEY"
