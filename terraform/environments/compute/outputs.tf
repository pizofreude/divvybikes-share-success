# Compute Environment Outputs
# These outputs provide compute infrastructure information

# Redshift Connection Information
output "redshift_endpoint" {
  description = "Redshift Serverless endpoint information"
  value       = module.compute.redshift_endpoint
}

output "redshift_jdbc_url" {
  description = "JDBC connection URL for Redshift Serverless"
  value       = module.compute.redshift_jdbc_url
}

output "redshift_connection_string" {
  description = "PostgreSQL-style connection string for Redshift Serverless"
  value       = module.compute.redshift_connection_string
  sensitive   = true
}

# Resource Information
output "redshift_namespace_name" {
  description = "Name of the Redshift Serverless namespace"
  value       = module.compute.redshift_namespace_name
}

output "redshift_workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  value       = module.compute.redshift_workgroup_name
}

output "redshift_database_name" {
  description = "Name of the default database"
  value       = module.compute.redshift_database_name
}

# Setup Information for Manual Configuration
output "setup_information" {
  description = "Information needed for manual setup process"
  value       = module.compute.setup_information
}

# Cost Information
output "monthly_usage_limit_rpus" {
  description = "Monthly usage limit in RPU-hours"
  value       = module.compute.monthly_usage_limit_rpus
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost based on usage limit"
  value       = module.compute.estimated_monthly_cost
}

# Integration Information
output "compute_configuration" {
  description = "Complete compute configuration for other services"
  value = {
    redshift_endpoint     = module.compute.redshift_endpoint
    database_name        = module.compute.redshift_database_name
    namespace_name       = module.compute.redshift_namespace_name
    workgroup_name       = module.compute.redshift_workgroup_name
    monthly_limit_rpus   = module.compute.monthly_usage_limit_rpus
    aws_region          = var.aws_region
  }
}
