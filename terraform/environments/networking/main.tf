# Networking Environment - Divvy Bikes Data Engineering Project
# This environment deploys the core networking infrastructure (VPC, subnets, security groups)

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
  #   key    = "networking/terraform.tfstate"
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

# Networking Module - Creates VPC, subnets, and security groups
module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # VPC Configuration
  vpc_cidr              = var.vpc_cidr
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  create_public_subnets = var.create_public_subnets

  # Tags
  common_tags = var.common_tags
}
