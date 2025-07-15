# Storage Environment - Divvy Bikes Data Engineering Project
# This environment deploys persistent storage resources (S3 buckets)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Backend configuration for storing Terraform state
  # Uncomment and configure after creating the state bucket manually
  # backend "s3" {
  #   bucket = "divvybikes-dev-terraform-state"
  #   key    = "storage/terraform.tfstate"
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

# Storage Module - Creates S3 buckets for medallion architecture
module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment

  # Storage retention policies
  bronze_archive_days      = var.bronze_archive_days
  bronze_deep_archive_days = var.bronze_deep_archive_days
  silver_archive_days      = var.silver_archive_days
  silver_deep_archive_days = var.silver_deep_archive_days
  gold_standard_ia_days    = var.gold_standard_ia_days
  gold_glacier_days        = var.gold_glacier_days

  # Version retention
  bronze_version_retention_days = var.bronze_version_retention_days
  silver_version_retention_days = var.silver_version_retention_days
  gold_version_retention_days   = var.gold_version_retention_days

  # Optional Terraform state bucket
  create_terraform_state_bucket = var.create_terraform_state_bucket

  common_tags = var.common_tags
}

# IAM Module - Creates roles and policies for storage access
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment

  # Pass S3 bucket ARNs to IAM module
  s3_bucket_arns = [
    module.storage.bronze_bucket_arn,
    module.storage.silver_bucket_arn,
    module.storage.gold_bucket_arn
  ]

  # Analyst access to processed data only
  analyst_s3_bucket_arns = [
    module.storage.silver_bucket_arn,
    module.storage.gold_bucket_arn
  ]

  # Create user for local Airflow development
  create_airflow_user   = var.create_airflow_user
  create_airflow_role   = var.create_airflow_role
  create_analyst_policy = var.create_analyst_policy

  common_tags = var.common_tags
}
