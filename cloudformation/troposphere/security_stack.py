#!/usr/bin/env python3
"""
Troposphere-generated CloudFormation template for security stack
"""

from troposphere import Template, Parameter, Output, Ref, GetAtt, Tags
from troposphere.iam import Role, Policy, PolicyType
from troposphere.logs import LogGroup
from troposphere.s3 import Bucket, BucketEncryption, ServerSideEncryptionRule, ServerSideEncryptionByDefault
from troposphere.kms import Key, Alias

def create_security_stack():
    template = Template()
    template.set_description("Enterprise Security Stack - KMS, S3, IAM, CloudWatch")

    # Parameters
    project_name = template.add_parameter(Parameter(
        "ProjectName",
        Type="String",
        Description="Project name for resource naming"
    ))

    environment = template.add_parameter(Parameter(
        "Environment", 
        Type="String",
        Description="Environment (dev/staging/production)",
        AllowedValues=["dev", "staging", "production"]
    ))

    # KMS Key for encryption
    kms_key = template.add_resource(Key(
        "SecurityKMSKey",
        Description="KMS key for security stack encryption",
        KeyPolicy={
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "Enable IAM User Permissions",
                    "Effect": "Allow",
                    "Principal": {"AWS": {"Fn::Sub": "arn:aws:iam::${AWS::AccountId}:root"}},
                    "Action": "kms:*",
                    "Resource": "*"
                }
            ]
        },
        Tags=Tags(
            Name={"Fn::Sub": "${ProjectName}-${Environment}-security-key"},
            Environment=Ref(environment)
        )
    ))

    # KMS Alias
    template.add_resource(Alias(
        "SecurityKMSAlias",
        AliasName={"Fn::Sub": "alias/${ProjectName}-${Environment}-security"},
        TargetKeyId=Ref(kms_key)
    ))

    # S3 Bucket for security artifacts
    security_bucket = template.add_resource(Bucket(
        "SecurityArtifactsBucket",
        BucketName={"Fn::Sub": "${ProjectName}-${Environment}-security-artifacts-${AWS::AccountId}"},
        BucketEncryption=BucketEncryption(
            ServerSideEncryptionConfiguration=[
                ServerSideEncryptionRule(
                    ServerSideEncryptionByDefault=ServerSideEncryptionByDefault(
                        SSEAlgorithm="aws:kms",
                        KMSMasterKeyID=Ref(kms_key)
                    )
                )
            ]
        ),
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": True,
            "BlockPublicPolicy": True,
            "IgnorePublicAcls": True,
            "RestrictPublicBuckets": True
        },
        Tags=Tags(
            Name={"Fn::Sub": "${ProjectName}-${Environment}-security-bucket"},
            Environment=Ref(environment)
        )
    ))

    # CloudWatch Log Group for security events
    security_log_group = template.add_resource(LogGroup(
        "SecurityLogGroup",
        LogGroupName={"Fn::Sub": "/aws/security/${ProjectName}-${Environment}"},
        RetentionInDays=365,
        KmsKeyId=Ref(kms_key)
    ))

    # IAM Role for security operations
    security_role = template.add_resource(Role(
        "SecurityOperationsRole",
        RoleName={"Fn::Sub": "${ProjectName}-${Environment}-security-ops"},
        AssumeRolePolicyDocument={
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "lambda.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        ManagedPolicyArns=[
            "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        ],
        Tags=Tags(
            Name={"Fn::Sub": "${ProjectName}-${Environment}-security-role"},
            Environment=Ref(environment)
        )
    ))

    # Security Policy
    template.add_resource(PolicyType(
        "SecurityPolicy",
        PolicyName="SecurityOperationsPolicy",
        PolicyDocument={
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                        "kms:Decrypt",
                        "kms:GenerateDataKey"
                    ],
                    "Resource": [
                        GetAtt(security_bucket, "Arn"),
                        {"Fn::Sub": "${SecurityArtifactsBucket}/*"},
                        GetAtt(security_log_group, "Arn"),
                        Ref(kms_key)
                    ]
                }
            ]
        },
        Roles=[Ref(security_role)]
    ))

    # Outputs
    template.add_output(Output(
        "KMSKeyId",
        Description="KMS Key ID for security encryption",
        Value=Ref(kms_key)
    ))

    template.add_output(Output(
        "SecurityBucketName",
        Description="S3 bucket for security artifacts",
        Value=Ref(security_bucket)
    ))

    template.add_output(Output(
        "SecurityRoleArn",
        Description="IAM role ARN for security operations",
        Value=GetAtt(security_role, "Arn")
    ))

    return template

if __name__ == "__main__":
    template = create_security_stack()
    print(template.to_json())