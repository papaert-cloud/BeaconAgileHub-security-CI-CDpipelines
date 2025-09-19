package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestNetworkSecurityModule(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../../terraform/modules/network-security",
		PlanFilePath: "./plan.out",
		Vars: map[string]interface{}{
			"project_name":            "test",
			"environment":             "dev",
			"vpc_cidr":               "10.0.0.0/16",
			"availability_zones":      []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.10.0/24", "10.0.20.0/24"},
			"database_subnet_cidrs":   []string{"10.0.100.0/24", "10.0.200.0/24"},
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	// Plan only test
	planStruct := terraform.InitAndPlan(t, terraformOptions)

	// Validate VPC creation
	resourceChanges := terraform.GetResourceChanges(t, planStruct)
	vpcFound := false
	for _, change := range resourceChanges {
		if change.Type == "aws_vpc" && change.Change.Actions[0] == "create" {
			vpcFound = true
			assert.Equal(t, "10.0.0.0/16", change.Change.After.(map[string]interface{})["cidr_block"])
		}
	}
	assert.True(t, vpcFound, "VPC should be created")

	// Validate security groups
	sgFound := false
	for _, change := range resourceChanges {
		if change.Type == "aws_security_group" {
			sgFound = true
		}
	}
	assert.True(t, sgFound, "Security groups should be created")
}