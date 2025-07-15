# Compute Environment - Divvy Bikes Data Engineering Project
# This environment deploys the compute infrastructure (Redshift Serverless)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for storing Terraform state
  # Uncomment and configure after creating the state bucket manually
  # backend "s3" {
  #   bucket = "divvybikes-dev-terraform-state"
  #   key    = "compute/terraform.tfstate"
  #   region = "ap-southeast-2"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Data source to get networking information from remote state
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

# Data source to get storage information from remote state
data "terraform_remote_state" "storage" {
  backend = "local"
  config = {
    path = "../storage/terraform.tfstate"
  }
}

# Compute Module - Creates Redshift Serverless for data warehousing
module "compute" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

  # State file paths
  networking_state_path = "../networking/terraform.tfstate"
  storage_state_path    = "../storage/terraform.tfstate"

  # Redshift Configuration
  redshift_admin_username = var.redshift_admin_username
  redshift_admin_password = var.redshift_admin_password
  redshift_database_name  = var.redshift_database_name

  # Capacity & Cost Control
  base_capacity_rpus        = var.base_capacity_rpus
  monthly_usage_limit_rpus  = var.monthly_usage_limit_rpus
  enable_usage_limits       = var.enable_usage_limits
  usage_limit_breach_action = var.usage_limit_breach_action

  # Network & Security
  publicly_accessible = var.publicly_accessible
  enable_logging      = var.enable_logging
  log_retention_days  = var.log_retention_days

  # Tags
  common_tags = var.common_tags
}
