locals {
  environment = "production"
  
  # Production-specific configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Subnet configurations
  public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnet_cidrs = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  
  # Security settings
  enable_deletion_protection = true
  backup_retention_days = 30
  log_retention_days = 90
  
  # Production-specific tags
  common_tags = {
    Environment = "production"
    CriticalSystem = "true"
    BackupRequired = "true"
    MonitoringLevel = "enhanced"
    ComplianceRequired = "true"
  }
}