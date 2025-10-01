# Tools — setup and usage

This folder contains small helper scripts used to manage the StackSet instances and run formatting/validation locally.

Install runtime tools (botocore):

```bash
make -C Infra/solutions/scenario-s003-000-secure-cicd-gha tools-install
```

Install developer tools (tests/linters):

```bash
make -C Infra/solutions/scenario-s003-000-secure-cicd-gha tools-dev-install
```

Usage examples

- Create StackSet instances:

```bash
python Infra/solutions/scenario-s003-000-secure-cicd-gha/tools/create_stackset_instances.py --stackset-name <name> --accounts 111111111111 --regions us-east-1
```

- Run terraform fmt locally (requires terraform installed):

```bash
Infra/solutions/scenario-s003-000-secure-cicd-gha/tools/terraform_fmt.sh
```
