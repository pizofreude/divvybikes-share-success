# Storage Module for Divvy Bikes Data Engineering Project
# This module creates S3 buckets for the medallion architecture (Bronze, Silver, Gold)
# with intelligent tiering and lifecycle policies for cost optimization

# Random suffix to ensure globally unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Bronze Layer S3 Bucket - Raw ingested data
resource "aws_s3_bucket" "bronze" {
  bucket = "${var.project_name}-${var.environment}-bronze-${random_string.bucket_suffix.result}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-bronze"
    Layer       = "bronze"
    Description = "Raw ingested data from Divvy bike share system"
  })
}

# Silver Layer S3 Bucket - Cleaned and transformed data
resource "aws_s3_bucket" "silver" {
  bucket = "${var.project_name}-${var.environment}-silver-${random_string.bucket_suffix.result}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-silver"
    Layer       = "silver"
    Description = "Cleaned and transformed data ready for analysis"
  })
}

# Gold Layer S3 Bucket - Business-ready aggregated data
resource "aws_s3_bucket" "gold" {
  bucket = "${var.project_name}-${var.environment}-gold-${random_string.bucket_suffix.result}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-gold"
    Layer       = "gold"
    Description = "Business-ready aggregated data and analytics"
  })
}

# Enable versioning for all buckets to protect against accidental deletions
resource "aws_s3_bucket_versioning" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "silver" {
  bucket = aws_s3_bucket.silver.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "gold" {
  bucket = aws_s3_bucket.gold.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for all buckets using SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "silver" {
  bucket = aws_s3_bucket.silver.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gold" {
  bucket = aws_s3_bucket.gold.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access for all buckets (security best practice)
resource "aws_s3_bucket_public_access_block" "bronze" {
  bucket = aws_s3_bucket.bronze.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "silver" {
  bucket = aws_s3_bucket.silver.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "gold" {
  bucket = aws_s3_bucket.gold.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Intelligent Tiering for Bronze bucket (raw data, accessed frequently then rarely)
resource "aws_s3_bucket_intelligent_tiering_configuration" "bronze_tiering" {
  bucket = aws_s3_bucket.bronze.id
  name   = "entire-bucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# Intelligent Tiering for Silver bucket (processed data, accessed regularly)
resource "aws_s3_bucket_intelligent_tiering_configuration" "silver_tiering" {
  bucket = aws_s3_bucket.silver.id
  name   = "entire-bucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 365
  }
}

# Lifecycle configuration for Bronze bucket
resource "aws_s3_bucket_lifecycle_configuration" "bronze_lifecycle" {
  bucket = aws_s3_bucket.bronze.id

  rule {
    id     = "bronze-lifecycle-rule"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    # Transition to Intelligent-Tiering after 1 day
    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Version management
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# Lifecycle configuration for Silver bucket
resource "aws_s3_bucket_lifecycle_configuration" "silver_lifecycle" {
  bucket = aws_s3_bucket.silver.id

  rule {
    id     = "silver-lifecycle-rule"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    # Transition to Intelligent-Tiering after 1 day
    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Version management - keep longer since this is processed data
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730  # 2 years
    }
  }
}

# Lifecycle configuration for Gold bucket
resource "aws_s3_bucket_lifecycle_configuration" "gold_lifecycle" {
  bucket = aws_s3_bucket.gold.id

  rule {
    id     = "gold-lifecycle-rule"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    # Keep in Standard storage longer as this is frequently accessed
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Version management - keep longest since this is business-critical data
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2555  # 7 years for compliance
    }
  }
}

# S3 bucket for storing Terraform state files (if using S3 backend)
resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-terraform-state-${random_string.bucket_suffix.result}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-terraform-state"
    Purpose     = "terraform-state"
    Description = "Terraform state files for infrastructure"
  })
}

# Versioning for Terraform state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for Terraform state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access for Terraform state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policies for additional security
# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Bucket policy for Bronze bucket - secure access only
resource "aws_s3_bucket_policy" "bronze_policy" {
  bucket = aws_s3_bucket.bronze.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.bronze.arn,
          "${aws_s3_bucket.bronze.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Bucket policy for Silver bucket - secure access only
resource "aws_s3_bucket_policy" "silver_policy" {
  bucket = aws_s3_bucket.silver.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.silver.arn,
          "${aws_s3_bucket.silver.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Bucket policy for Gold bucket - secure access only
resource "aws_s3_bucket_policy" "gold_policy" {
  bucket = aws_s3_bucket.gold.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.gold.arn,
          "${aws_s3_bucket.gold.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
