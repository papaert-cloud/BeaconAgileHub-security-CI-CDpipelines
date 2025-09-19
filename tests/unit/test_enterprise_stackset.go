package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEnterpriseStackSetModule(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../../terraform/modules/enterprise-stackset",
		PlanFilePath: "./stackset-plan.out",
		Vars: map[string]interface{}{
			"org_name":             "test-corp",
			"environment":          "dev",
			"aws_region":          "us-west-2",
			"vpc_cidr":            "10.0.0.0/16",
			"enable_multi_account": false,
			"target_accounts": []map[string]interface{}{
				{
					"account_id":  "123456789012",
					"region":      "us-west-2",
					"environment": "dev",
					"vpc_cidr":    "10.10.0.0/16",
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	// Plan only test
	planStruct := terraform.InitAndPlan(t, terraformOptions)

	// Validate StackSet creation
	resourceChanges := terraform.GetResourceChanges(t, planStruct)
	stackSetFound := false
	for _, change := range resourceChanges {
		if change.Type == "aws_cloudformation_stack_set" && change.Change.Actions[0] == "create" {
			stackSetFound = true
			assert.Contains(t, change.Change.After.(map[string]interface{})["name"], "test-corp")
		}
	}
	assert.True(t, stackSetFound, "StackSet should be created")

	// Validate StackSet Instance
	instanceFound := false
	for _, change := range resourceChanges {
		if change.Type == "aws_cloudformation_stack_set_instance" {
			instanceFound = true
		}
	}
	assert.True(t, instanceFound, "StackSet instance should be created")
}