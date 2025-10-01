#!/usr/bin/env python3
"""Create CloudFormation StackSet instances in target accounts/regions.

Usage: python create_stackset_instances.py --stackset-name NAME --accounts 111111111111 222222222222 --regions us-east-1
"""
import argparse
from botocore.session import Session
import sys


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--stackset-name", required=True)
    p.add_argument("--accounts", nargs='+', required=True)
    p.add_argument("--regions", nargs='+', required=True)
    args = p.parse_args()

    session = Session()
    cf = session.create_client('cloudformation')

    try:
        resp = cf.create_stack_instances(
            StackSetName=args.stackset_name,
            Accounts=args.accounts,
            Regions=args.regions,
        )
        print('CreateStackInstances response:', resp)
    except Exception as e:
        print('Error creating instances:', e, file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
