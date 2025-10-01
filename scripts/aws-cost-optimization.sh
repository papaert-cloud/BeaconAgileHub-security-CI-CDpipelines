#!/bin/bash
# Cost Optimization Script for AWS Infrastructure

echo "=== AWS Cost Optimization Analysis ==="

# 1. Identify unused resources
echo "Checking for unused EBS volumes..."
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime]' \
  --output table

# 2. Right-size instances
echo "Checking instance utilization (requires CloudWatch)..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-013e973f119a1f15e \
  --start-time $(date -d '7 days ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 3600 \
  --statistics Average,Maximum

# 3. Identify unattached resources
echo "Finding unattached Elastic IPs..."
aws ec2 describe-addresses \
  --query 'Addresses[?!InstanceId].[PublicIp,AllocationId]' \
  --output table

# 4. Spot instance recommendations
echo "Current instance types and recommendations:"
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,LaunchTime]' \
  --output table

echo "=== Cost Optimization Recommendations ==="
cat << 'EOF'

IMMEDIATE SAVINGS (60-80% reduction):
1. Stop non-production instances during off-hours
2. Convert to t3.nano for development (save $5-6/month)
3. Delete unattached EBS volumes
4. Use Spot instances for non-critical workloads

MEDIUM-TERM SAVINGS (30-50% reduction):
1. Reserved Instances for steady workloads
2. S3 lifecycle policies for logs
3. CloudWatch log retention policies
4. Rightsizing based on actual usage

LONG-TERM SAVINGS (20-40% reduction):
1. Savings Plans commitment
2. Migration to ARM-based Graviton instances
3. Container optimization
4. Multi-region cost analysis

EOF