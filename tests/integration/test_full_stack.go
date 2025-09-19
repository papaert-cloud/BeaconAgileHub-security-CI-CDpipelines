package test

import (
	"testing"
	"time"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
)

func TestFullStackDeployment(t *testing.T) {
	t.Parallel()

	awsRegion := "us-west-2"
	
	terraformOptions := &terraform.Options{
		TerraformDir: "../../terragrunt/environments/dev",
		Vars: map[string]interface{}{
			"project_name": "test-integration",
			"environment":  "dev",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
		RetryableTerraformErrors: map[string]string{
			"RequestError: send request failed": "Temporary AWS API error",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Deploy infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Validate VPC exists
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId)

	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

	// Validate subnets
	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Len(t, privateSubnets, 2)

	// Validate security groups
	sgId := terraform.Output(t, terraformOptions, "vpc_endpoints_sg_id")
	assert.NotEmpty(t, sgId)

	// Validate VPC endpoints
	s3EndpointId := terraform.Output(t, terraformOptions, "s3_endpoint_id")
	assert.NotEmpty(t, s3EndpointId)
}