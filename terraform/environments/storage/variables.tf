# Storage Environment Variables
# These variables configure the storage environment deployment

# Basic Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "divvybikes"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

# Storage Lifecycle Configuration
variable "bronze_archive_days" {
  description = "Number of days before moving Bronze data to Archive tier"
  type        = number
  default     = 90
}

variable "bronze_deep_archive_days" {
  description = "Number of days before moving Bronze data to Deep Archive tier"
  type        = number
  default     = 180
}

variable "silver_archive_days" {
  description = "Number of days before moving Silver data to Archive tier"
  type        = number
  default     = 180
}

variable "silver_deep_archive_days" {
  description = "Number of days before moving Silver data to Deep Archive tier"
  type        = number
  default     = 365
}

variable "gold_standard_ia_days" {
  description = "Number of days before moving Gold data to Standard-IA"
  type        = number
  default     = 30
}

variable "gold_glacier_days" {
  description = "Number of days before moving Gold data to Glacier"
  type        = number
  default     = 90
}

# Version Retention Configuration
variable "bronze_version_retention_days" {
  description = "Number of days to retain non-current versions in Bronze bucket"
  type        = number
  default     = 365
}

variable "silver_version_retention_days" {
  description = "Number of days to retain non-current versions in Silver bucket"
  type        = number
  default     = 730
}

variable "gold_version_retention_days" {
  description = "Number of days to retain non-current versions in Gold bucket"
  type        = number
  default     = 2555
}

# IAM Configuration
variable "create_airflow_user" {
  description = "Whether to create an IAM user for Airflow (for local Docker access)"
  type        = bool
  default     = true
}

variable "create_airflow_role" {
  description = "Whether to create an IAM role for Airflow (for assume role access)"
  type        = bool
  default     = false
}

variable "create_analyst_policy" {
  description = "Whether to create policies and groups for data analysts"
  type        = bool
  default     = false
}

# Optional Features
variable "create_terraform_state_bucket" {
  description = "Whether to create a bucket for Terraform state files"
  type        = bool
  default     = false
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "divvybikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
    Component   = "storage"
  }
}
