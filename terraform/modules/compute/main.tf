# Compute Module for Divvy Bikes Data Engineering Project
# This module creates Redshift Serverless resources for data warehousing

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get networking information from remote state
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = var.networking_state_path
  }
}

# Data source to get storage information from remote state
data "terraform_remote_state" "storage" {
  backend = "local"
  config = {
    path = var.storage_state_path
  }
}

# Redshift Serverless Namespace
resource "aws_redshiftserverless_namespace" "divvy" {
  namespace_name = "${var.project_name}-${var.environment}"
  
  # Database configuration
  admin_username = var.redshift_admin_username
  admin_user_password = var.redshift_admin_password
  db_name        = var.redshift_database_name

  # IAM roles for accessing S3
  iam_roles = [data.terraform_remote_state.storage.outputs.redshift_role_arn]

  # Security and compliance
  kms_key_id     = var.kms_key_id
  log_exports    = var.log_exports

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-namespace"
    Type = "DataWarehouse"
  })
}

# Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "divvy" {
  namespace_name = aws_redshiftserverless_namespace.divvy.namespace_name
  workgroup_name = "${var.project_name}-${var.environment}"

  # Capacity configuration
  base_capacity = var.base_capacity_rpus

  # Network configuration
  enhanced_vpc_routing   = var.enhanced_vpc_routing
  publicly_accessible   = var.publicly_accessible
  
  # For public access, don't specify subnet_ids or security_group_ids
  # Only use VPC networking when enhanced_vpc_routing is enabled
  subnet_ids         = var.enhanced_vpc_routing ? data.terraform_remote_state.networking.outputs.private_subnet_ids : null
  security_group_ids = var.enhanced_vpc_routing ? [data.terraform_remote_state.networking.outputs.redshift_security_group_id] : null

  # Configuration parameters
  config_parameter {
    parameter_key   = "max_query_execution_time"
    parameter_value = "14400" # 4 hours
  }

  config_parameter {
    parameter_key   = "datestyle"
    parameter_value = "ISO, MDY"
  }

  config_parameter {
    parameter_key   = "enable_user_activity_logging"
    parameter_value = "true"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-workgroup"
    Type = "DataWarehouse"
  })
}

# Create database schema for Divvy data
resource "aws_redshiftserverless_usage_limit" "query_limit" {
  count = var.enable_usage_limits ? 1 : 0

  resource_arn   = aws_redshiftserverless_workgroup.divvy.arn
  usage_type     = "serverless-compute"
  amount         = var.monthly_usage_limit_rpus
  period         = "monthly"
  breach_action  = var.usage_limit_breach_action
}

# CloudWatch Log Group for Redshift Serverless
resource "aws_cloudwatch_log_group" "redshift_logs" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/redshift-serverless/${aws_redshiftserverless_namespace.divvy.namespace_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-logs"
  })
}

# Note: Database initialization and Airflow connection configuration
# are now handled through the clean setup process in dbt_divvy/setup/
# See setup documentation for manual connection configuration steps
