# Compute Environment Variables
# Variables for the compute environment

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
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-southeast-2"
}

# Redshift Configuration
variable "redshift_admin_username" {
  description = "Admin username for Redshift Serverless"
  type        = string
  default     = "admin"
}

variable "redshift_admin_password" {
  description = "Admin password for Redshift Serverless"
  type        = string
  sensitive   = true
}

variable "redshift_database_name" {
  description = "Name of the default database in Redshift"
  type        = string
  default     = "divvy"
}

# Capacity Configuration
variable "base_capacity_rpus" {
  description = "Base capacity for Redshift Serverless (minimum: 8 RPUs)"
  type        = number
  default     = 8
  
  validation {
    condition     = var.base_capacity_rpus >= 8
    error_message = "Base capacity must be at least 8 RPUs."
  }
}

variable "monthly_usage_limit_rpus" {
  description = "Monthly usage limit in RPU-hours for cost control"
  type        = number
  default     = 100
}

variable "enable_usage_limits" {
  description = "Whether to enable usage limits for cost control"
  type        = bool
  default     = true
}

variable "usage_limit_breach_action" {
  description = "Action to take when usage limit is breached"
  type        = string
  default     = "log"
  
  validation {
    condition     = contains(["log", "emit-metric", "deactivate"], var.usage_limit_breach_action)
    error_message = "Breach action must be one of: log, emit-metric, deactivate."
  }
}

# Network & Security Configuration
variable "publicly_accessible" {
  description = "Whether Redshift should be publicly accessible (for local development)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "DivvyBikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
    CostCenter  = "DataEngineering"
  }
}
