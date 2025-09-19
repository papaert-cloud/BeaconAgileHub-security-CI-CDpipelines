include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "../../../../terraform/modules//network-security"
}

inputs = {
  # Inherit from environment configuration
  vpc_cidr = local.vpc_cidr
  availability_zones = local.availability_zones
  public_subnet_cidrs = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs
  
  # Module-specific inputs
  project_name = "sbom-security-pipeline"
  environment = local.environment
  common_tags = local.common_tags
}