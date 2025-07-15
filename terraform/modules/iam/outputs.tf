# IAM Module Outputs
# These outputs provide IAM resource information to other modules

# Redshift Role Outputs
output "redshift_role_arn" {
  description = "ARN of the IAM role for Redshift Serverless"
  value       = aws_iam_role.redshift_role.arn
}

output "redshift_role_name" {
  description = "Name of the IAM role for Redshift Serverless"
  value       = aws_iam_role.redshift_role.name
}

# Airflow Role Outputs (conditional)
output "airflow_role_arn" {
  description = "ARN of the IAM role for Airflow"
  value       = var.create_airflow_role ? aws_iam_role.airflow_role[0].arn : null
}

output "airflow_role_name" {
  description = "Name of the IAM role for Airflow"
  value       = var.create_airflow_role ? aws_iam_role.airflow_role[0].name : null
}

# Airflow User Outputs (conditional)
output "airflow_user_name" {
  description = "Name of the IAM user for Airflow"
  value       = var.create_airflow_user ? aws_iam_user.airflow_user[0].name : null
}

output "airflow_user_arn" {
  description = "ARN of the IAM user for Airflow"
  value       = var.create_airflow_user ? aws_iam_user.airflow_user[0].arn : null
}

output "airflow_access_key_id" {
  description = "Access key ID for Airflow user"
  value       = var.create_airflow_user ? aws_iam_access_key.airflow_user_key[0].id : null
  sensitive   = true
}

output "airflow_secret_access_key" {
  description = "Secret access key for Airflow user"
  value       = var.create_airflow_user ? aws_iam_access_key.airflow_user_key[0].secret : null
  sensitive   = true
}

# Policy ARNs
output "redshift_s3_policy_arn" {
  description = "ARN of the S3 policy for Redshift"
  value       = aws_iam_policy.redshift_s3_policy.arn
}

output "airflow_policy_arn" {
  description = "ARN of the policy for Airflow"
  value       = var.create_airflow_role || var.create_airflow_user ? aws_iam_policy.airflow_policy[0].arn : null
}

output "analyst_policy_arn" {
  description = "ARN of the read-only policy for analysts"
  value       = var.create_analyst_policy ? aws_iam_policy.analyst_policy[0].arn : null
}

# Group Information
output "analysts_group_name" {
  description = "Name of the analysts IAM group"
  value       = var.create_analyst_policy ? aws_iam_group.analysts[0].name : null
}

output "analysts_group_arn" {
  description = "ARN of the analysts IAM group"
  value       = var.create_analyst_policy ? aws_iam_group.analysts[0].arn : null
}

# Convenient output for Airflow configuration
output "airflow_aws_credentials" {
  description = "AWS credentials for Airflow configuration (use carefully)"
  value = var.create_airflow_user ? {
    access_key_id     = aws_iam_access_key.airflow_user_key[0].id
    secret_access_key = aws_iam_access_key.airflow_user_key[0].secret
    user_arn          = aws_iam_user.airflow_user[0].arn
  } : null
  sensitive = true
}
