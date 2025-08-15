# Storage Module Outputs
# These outputs provide S3 bucket information to other modules and environments

# Bronze Layer Outputs
output "bronze_bucket_id" {
  description = "ID of the Bronze layer S3 bucket"
  value       = aws_s3_bucket.bronze.id
}

output "bronze_bucket_arn" {
  description = "ARN of the Bronze layer S3 bucket"
  value       = aws_s3_bucket.bronze.arn
}

output "bronze_bucket_domain_name" {
  description = "Domain name of the Bronze layer S3 bucket"
  value       = aws_s3_bucket.bronze.bucket_domain_name
}

output "bronze_bucket_regional_domain_name" {
  description = "Regional domain name of the Bronze layer S3 bucket"
  value       = aws_s3_bucket.bronze.bucket_regional_domain_name
}

# Silver Layer Outputs
output "silver_bucket_id" {
  description = "ID of the Silver layer S3 bucket"
  value       = aws_s3_bucket.silver.id
}

output "silver_bucket_arn" {
  description = "ARN of the Silver layer S3 bucket"
  value       = aws_s3_bucket.silver.arn
}

output "silver_bucket_domain_name" {
  description = "Domain name of the Silver layer S3 bucket"
  value       = aws_s3_bucket.silver.bucket_domain_name
}

output "silver_bucket_regional_domain_name" {
  description = "Regional domain name of the Silver layer S3 bucket"
  value       = aws_s3_bucket.silver.bucket_regional_domain_name
}

# Gold Layer Outputs
output "gold_bucket_id" {
  description = "ID of the Gold layer S3 bucket"
  value       = aws_s3_bucket.gold.id
}

output "gold_bucket_arn" {
  description = "ARN of the Gold layer S3 bucket"
  value       = aws_s3_bucket.gold.arn
}

output "gold_bucket_domain_name" {
  description = "Domain name of the Gold layer S3 bucket"
  value       = aws_s3_bucket.gold.bucket_domain_name
}

output "gold_bucket_regional_domain_name" {
  description = "Regional domain name of the Gold layer S3 bucket"
  value       = aws_s3_bucket.gold.bucket_regional_domain_name
}

# Terraform State Bucket Outputs (conditional)
output "terraform_state_bucket_id" {
  description = "ID of the Terraform state S3 bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].id : null
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].arn : null
}

# Comprehensive bucket information for Airflow DAGs
output "data_buckets" {
  description = "Map of all data layer buckets for easy reference in Airflow"
  value = {
    bronze = {
      id   = aws_s3_bucket.bronze.id
      arn  = aws_s3_bucket.bronze.arn
      name = aws_s3_bucket.bronze.bucket
    }
    silver = {
      id   = aws_s3_bucket.silver.id
      arn  = aws_s3_bucket.silver.arn
      name = aws_s3_bucket.silver.bucket
    }
    gold = {
      id   = aws_s3_bucket.gold.id
      arn  = aws_s3_bucket.gold.arn
      name = aws_s3_bucket.gold.bucket
    }
  }
}

# Bucket names only (useful for configuration files)
output "bucket_names" {
  description = "Names of all data layer buckets"
  value = {
    bronze = aws_s3_bucket.bronze.bucket
    silver = aws_s3_bucket.silver.bucket
    gold   = aws_s3_bucket.gold.bucket
  }
}

# Random suffix for reference
output "bucket_suffix" {
  description = "Random suffix used for bucket names"
  value       = random_string.bucket_suffix.result
}

# =============================================================================
# Glue Data Catalog Outputs
# =============================================================================

# Glue Database for Bronze layer
output "glue_bronze_database_name" {
  description = "Name of the Glue database for Bronze layer external tables"
  value       = aws_glue_catalog_database.bronze_db.name
}

output "glue_bronze_database_arn" {
  description = "ARN of the Glue database for Bronze layer external tables"
  value       = aws_glue_catalog_database.bronze_db.arn
}

# Glue Catalog Tables
output "glue_divvy_trips_table_name" {
  description = "Name of the Glue catalog table for divvy trips data"
  value       = aws_glue_catalog_table.divvy_trips.name
}

output "glue_weather_data_table_name" {
  description = "Name of the Glue catalog table for weather data"
  value       = aws_glue_catalog_table.weather_data.name
}

output "glue_gbfs_stations_table_name" {
  description = "Name of the Glue catalog table for GBFS stations data"
  value       = aws_glue_catalog_table.gbfs_stations.name
}
