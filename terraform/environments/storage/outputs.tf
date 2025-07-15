# Storage Environment Outputs
# These outputs provide essential information for other environments and external use

# S3 Bucket Information
output "bronze_bucket_name" {
  description = "Name of the Bronze layer S3 bucket"
  value       = module.storage.bronze_bucket_id
}

output "silver_bucket_name" {
  description = "Name of the Silver layer S3 bucket"
  value       = module.storage.silver_bucket_id
}

output "gold_bucket_name" {
  description = "Name of the Gold layer S3 bucket"
  value       = module.storage.gold_bucket_id
}

output "bucket_names" {
  description = "All bucket names for easy reference"
  value       = module.storage.bucket_names
}

output "data_buckets" {
  description = "Complete bucket information for Airflow configuration"
  value       = module.storage.data_buckets
}

# IAM Information for Airflow
output "airflow_access_key_id" {
  description = "Access Key ID for Airflow user (use in environment variables)"
  value       = module.iam.airflow_access_key_id
  sensitive   = true
}

output "airflow_secret_access_key" {
  description = "Secret Access Key for Airflow user (use in environment variables)"
  value       = module.iam.airflow_secret_access_key
  sensitive   = true
}

output "redshift_role_arn" {
  description = "ARN of the IAM role for Redshift Serverless"
  value       = module.iam.redshift_role_arn
}

# Terraform State Bucket (if created)
output "terraform_state_bucket_name" {
  description = "Name of the Terraform state bucket (if created)"
  value       = module.storage.terraform_state_bucket_id
}

# Configuration for Next Phase
output "storage_configuration" {
  description = "Configuration object for use in compute environment"
  value = {
    bucket_names = module.storage.bucket_names
    bucket_arns = {
      bronze = module.storage.bronze_bucket_arn
      silver = module.storage.silver_bucket_arn
      gold   = module.storage.gold_bucket_arn
    }
    redshift_role_arn = module.iam.redshift_role_arn
    aws_region        = var.aws_region
  }
}
