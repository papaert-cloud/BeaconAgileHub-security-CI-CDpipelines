locals {
  environment = "dev"
  
  # Development-specific configuration
  vpc_cidr = "10.10.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Subnet configurations
  public_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]
  private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  database_subnet_cidrs = ["10.10.201.0/24", "10.10.202.0/24"]
  
  # Security settings
  enable_deletion_protection = false
  backup_retention_days = 7
  log_retention_days = 3
  
  # Development-specific tags
  common_tags = {
    Environment = "development"
    AutoShutdown = "true"
    BackupRequired = "false"
    CostOptimized = "true"
  }
}