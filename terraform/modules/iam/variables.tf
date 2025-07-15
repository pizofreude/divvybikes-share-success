# IAM Module Variables
# These variables allow customization of IAM resources

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

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that services need access to"
  type        = list(string)
  default     = []
}

variable "analyst_s3_bucket_arns" {
  description = "List of S3 bucket ARNs that analysts need read access to (typically Silver and Gold)"
  type        = list(string)
  default     = []
}

variable "create_airflow_role" {
  description = "Whether to create an IAM role for Airflow (for assume role access)"
  type        = bool
  default     = false
}

variable "create_airflow_user" {
  description = "Whether to create an IAM user for Airflow (for local Docker access)"
  type        = bool
  default     = true
}

variable "create_analyst_policy" {
  description = "Whether to create policies and groups for data analysts"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "divvybikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
  }
}
