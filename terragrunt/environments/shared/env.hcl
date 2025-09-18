locals {
  environment = "shared"
  
  common_tags = {
    Environment = "shared"
    Project     = "sbom-security-pipeline"
    ManagedBy   = "terragrunt"
    Owner       = "platform-team"
    CostCenter  = "shared-services"
  }
}