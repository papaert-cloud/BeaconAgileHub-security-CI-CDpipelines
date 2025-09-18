.PHONY: test-unit test-integration test-security validate-cfn validate-terraform cost-estimate test-all setup clean

# Test targets
test-unit:
	@echo "Running Terratest unit tests..."
	cd tests && go mod tidy && go test -v ./unit/... -timeout 10m

test-integration:
	@echo "Running integration tests..."
	cd tests && go test -v ./integration/... -timeout 30m

test-security:
	@echo "Running security compliance tests..."
	cd tests && python -m pytest security/ -v

validate-cfn:
	@echo "Validating CloudFormation templates..."
	cfn-lint cloudformation/templates/*.yaml
	cfn-lint cloudformation/templates/*.yaml --include-checks I --ignore-checks W

validate-terraform:
	@echo "Validating Terraform modules..."
	terraform fmt -check -recursive terraform/
	@for dir in terraform/modules/*/; do \
		echo "Validating $$dir"; \
		cd "$$dir" && terraform init -backend=false && terraform validate && cd - > /dev/null; \
	done

cost-estimate:
	@echo "Generating cost estimates..."
	infracost breakdown --path=terraform/ --format=table

security-scan:
	@echo "Running security scans..."
	checkov -d . --framework terraform,cloudformation --output sarif --output-file-path checkov-results.sarif

test-all: validate-terraform validate-cfn test-unit test-security

setup:
	@echo "Setting up development environment..."
	cd tests && go mod tidy
	pip install -r cloudformation/requirements.txt
	pip install pytest boto3 moto

clean:
	@echo "Cleaning up test artifacts..."
	rm -rf tests/**/.terraform*
	rm -rf tests/**/terraform.tfstate*
	rm -f checkov-results.sarif
	rm -f infracost.json