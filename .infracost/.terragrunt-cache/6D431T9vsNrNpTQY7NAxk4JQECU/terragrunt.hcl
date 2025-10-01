locals {
  region = "us-east-1"
}

terraform {
  source = "./terraform"
}

inputs = {
  region                       = local.region
  administration_role_arn      = "arn:aws:iam::005965605891:role/OrganizationAccountAccessRole" # replace with your admin role
  lambda_code_bucket           = "my-deployment-bucket"
  target_account_ids           = ["111111111111", "222222222222"]
}
