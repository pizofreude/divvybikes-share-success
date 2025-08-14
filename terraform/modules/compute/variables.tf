# Compute Module Variables
# These variables configure the Redshift Serverless resources

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

# State File Paths
variable "networking_state_path" {
  description = "Path to the networking environment Terraform state file"
  type        = string
  default     = "../networking/terraform.tfstate"
}

variable "storage_state_path" {
  description = "Path to the storage environment Terraform state file"
  type        = string
  default     = "../storage/terraform.tfstate"
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
  description = "Base capacity in RPUs (Redshift Processing Units) for the workgroup"
  type        = number
  default     = 8
  
  validation {
    condition     = var.base_capacity_rpus >= 8 && var.base_capacity_rpus <= 512
    error_message = "Base capacity must be between 8 and 512 RPUs."
  }
}

# Network Configuration
variable "publicly_accessible" {
  description = "Whether the Redshift Serverless endpoint is publicly accessible"
  type        = bool
  default     = true
}

# Security Configuration
variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "log_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["userlog", "connectionlog", "useractivitylog"]
}

# Usage Limits
variable "enable_usage_limits" {
  description = "Whether to enable usage limits to control costs"
  type        = bool
  default     = true
}

variable "monthly_usage_limit_rpus" {
  description = "Monthly usage limit in RPU-hours"
  type        = number
  default     = 100  # ~$14.40 AUD at $0.144/RPU-hour
}

variable "usage_limit_breach_action" {
  description = "Action to take when usage limit is breached"
  type        = string
  default     = "log"  # Options: log, emit-metric, deactivate
  
  validation {
    condition     = contains(["log", "emit-metric", "deactivate"], var.usage_limit_breach_action)
    error_message = "Usage limit breach action must be one of: log, emit-metric, deactivate."
  }
}

# Logging Configuration
variable "enable_logging" {
  description = "Whether to enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Enhanced VPC Routing Configuration
variable "enhanced_vpc_routing" {
  description = "Whether to enable enhanced VPC routing for Redshift workgroup. When enabled, all traffic goes through VPC, disabling public accessibility. Disable for development access."
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
    Component   = "compute"
  }
}
