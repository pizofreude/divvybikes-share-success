# Compute Module Outputs
# These outputs provide Redshift Serverless connection information

# Redshift Serverless Namespace Information
output "redshift_namespace_name" {
  description = "Name of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.divvy.namespace_name
}

output "redshift_namespace_id" {
  description = "ID of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.divvy.namespace_id
}

output "redshift_namespace_arn" {
  description = "ARN of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.divvy.arn
}

# Redshift Serverless Workgroup Information
output "redshift_workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.divvy.workgroup_name
}

output "redshift_workgroup_id" {
  description = "ID of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.divvy.workgroup_id
}

output "redshift_workgroup_arn" {
  description = "ARN of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.divvy.arn
}

# Connection Information
output "redshift_endpoint" {
  description = "Redshift Serverless endpoint information"
  value = {
    address = aws_redshiftserverless_workgroup.divvy.endpoint[0].address
    port    = aws_redshiftserverless_workgroup.divvy.endpoint[0].port
  }
}

output "redshift_jdbc_url" {
  description = "JDBC connection URL for Redshift Serverless"
  value       = "jdbc:redshift://${aws_redshiftserverless_workgroup.divvy.endpoint[0].address}:${aws_redshiftserverless_workgroup.divvy.endpoint[0].port}/${var.redshift_database_name}"
}

output "redshift_connection_string" {
  description = "PostgreSQL-style connection string for Redshift Serverless"
  value       = "postgresql://${var.redshift_admin_username}@${aws_redshiftserverless_workgroup.divvy.endpoint[0].address}:${aws_redshiftserverless_workgroup.divvy.endpoint[0].port}/${var.redshift_database_name}"
  sensitive   = true
}

# Database Information
output "redshift_database_name" {
  description = "Name of the default database"
  value       = var.redshift_database_name
}

output "redshift_admin_username" {
  description = "Admin username for Redshift"
  value       = var.redshift_admin_username
}

# Usage Limit Information
output "usage_limit_arn" {
  description = "ARN of the usage limit (if enabled)"
  value       = var.enable_usage_limits ? aws_redshiftserverless_usage_limit.query_limit[0].arn : null
}

output "monthly_usage_limit_rpus" {
  description = "Monthly usage limit in RPU-hours"
  value       = var.monthly_usage_limit_rpus
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (if enabled)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.redshift_logs[0].name : null
}

# Configuration for Manual Setup
output "setup_information" {
  description = "Information needed for manual setup process"
  value = {
    note = "Database initialization and Airflow connection setup are handled through the clean setup process in dbt_divvy/setup/. See setup documentation for configuration steps."
  }
}

# Configuration for Airflow
output "airflow_redshift_connection" {
  description = "Configuration object for Airflow Redshift connection"
  value = {
    conn_id     = "redshift_default"
    conn_type   = "redshift"
    host        = aws_redshiftserverless_workgroup.divvy.endpoint[0].address
    port        = aws_redshiftserverless_workgroup.divvy.endpoint[0].port
    schema      = var.redshift_database_name
    login       = var.redshift_admin_username
    password    = var.redshift_admin_password
    extra = jsonencode({
      workgroup = aws_redshiftserverless_workgroup.divvy.workgroup_name
      namespace = aws_redshiftserverless_namespace.divvy.namespace_name
      region    = data.aws_region.current.name
    })
  }
  sensitive = true
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost based on usage limit"
  value = {
    max_rpu_hours    = var.monthly_usage_limit_rpus
    cost_per_rpu_hour = 0.144  # USD
    max_monthly_cost_usd = var.monthly_usage_limit_rpus * 0.144
    max_monthly_cost_aud = var.monthly_usage_limit_rpus * 0.144 * 1.5  # Approximate conversion
  }
}
