# IAM Module for Divvy Bikes Data Engineering Project
# This module creates IAM roles, policies, and users for secure access to AWS resources

# Data source for current AWS account information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# IAM Role for Redshift Serverless
resource "aws_iam_role" "redshift_role" {
  name = "${var.project_name}-${var.environment}-redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-role"
    Type = "ServiceRole"
  })
}

# IAM Policy for Redshift to access S3 buckets
resource "aws_iam_policy" "redshift_s3_policy" {
  name        = "${var.project_name}-${var.environment}-redshift-s3-policy"
  description = "Policy for Redshift to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          for bucket_arn in var.s3_bucket_arns : bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          for bucket_arn in var.s3_bucket_arns : "${bucket_arn}/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# Attach S3 policy to Redshift role
resource "aws_iam_role_policy_attachment" "redshift_s3_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_s3_policy.arn
}

# IAM Policy for Redshift to access AWS Glue Data Catalog
resource "aws_iam_policy" "redshift_glue_policy" {
  name        = "${var.project_name}-${var.environment}-redshift-glue-policy"
  description = "Policy for Redshift to access AWS Glue Data Catalog for external tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchUpdatePartition",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:UpdateTable"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# Attach Glue policy to Redshift role
resource "aws_iam_role_policy_attachment" "redshift_glue_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_glue_policy.arn
}

# IAM Role for Airflow (local Docker) to access AWS services
resource "aws_iam_role" "airflow_role" {
  count = var.create_airflow_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-airflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-airflow-role"
    Type = "ApplicationRole"
  })
}

# IAM Policy for Airflow to access S3 and Redshift
resource "aws_iam_policy" "airflow_policy" {
  count       = var.create_airflow_role || var.create_airflow_user ? 1 : 0
  name        = "${var.project_name}-${var.environment}-airflow-policy"
  description = "Policy for Airflow to access S3 and Redshift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 access for data operations
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketVersions",
          "s3:GetBucketPolicy",
          "s3:GetBucketPolicyStatus"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for bucket_arn in var.s3_bucket_arns : "${bucket_arn}/*"]
        )
      },
      # AWS Glue Data Catalog access for external tables
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchUpdatePartition",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:UpdateTable",
          "glue:GetCatalogImportStatus"
        ]
        Resource = [
          "arn:aws:glue:*:*:catalog",
          "arn:aws:glue:*:*:database/*",
          "arn:aws:glue:*:*:table/*/*"
        ]
      },
      # IAM permissions for user management and policy access
      {
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:GetRole",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      # Redshift Serverless access
      {
        Effect = "Allow"
        Action = [
          "redshift-serverless:GetWorkgroup",
          "redshift-serverless:GetNamespace",
          "redshift-serverless:ListWorkgroups",
          "redshift-serverless:ListNamespaces"
        ]
        Resource = "*"
      },
      # Redshift Data API access
      {
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:ListStatements",
          "redshift-data:CancelStatement"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# Attach Airflow policy to Airflow role
resource "aws_iam_role_policy_attachment" "airflow_policy_attachment" {
  count      = var.create_airflow_role ? 1 : 0
  role       = aws_iam_role.airflow_role[0].name
  policy_arn = aws_iam_policy.airflow_policy[0].arn
}

# IAM User for local development (alternative to IAM role for Airflow)
resource "aws_iam_user" "airflow_user" {
  count = var.create_airflow_user ? 1 : 0
  name  = "${var.project_name}-${var.environment}-airflow-user"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-airflow-user"
    Type = "ServiceUser"
  })
}

# Attach Airflow policy to Airflow user
resource "aws_iam_user_policy_attachment" "airflow_user_policy_attachment" {
  count      = var.create_airflow_user ? 1 : 0
  user       = aws_iam_user.airflow_user[0].name
  policy_arn = aws_iam_policy.airflow_policy[0].arn
}

# Access key for Airflow user (for local Docker environment)
resource "aws_iam_access_key" "airflow_user_key" {
  count = var.create_airflow_user ? 1 : 0
  user  = aws_iam_user.airflow_user[0].name
}

# IAM Policy for data analysts (read-only access)
resource "aws_iam_policy" "analyst_policy" {
  count       = var.create_analyst_policy ? 1 : 0
  name        = "${var.project_name}-${var.environment}-analyst-policy"
  description = "Read-only policy for data analysts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read-only S3 access to Silver and Gold layers
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          for bucket_arn in var.analyst_s3_bucket_arns : bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          for bucket_arn in var.analyst_s3_bucket_arns : "${bucket_arn}/*"
        ]
      },
      # Read-only Redshift access
      {
        Effect = "Allow"
        Action = [
          "redshift-serverless:GetWorkgroup",
          "redshift-serverless:GetNamespace"
        ]
        Resource = "*"
      },
      # Redshift Data API read access
      {
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "redshift-data:StatementType" = "SELECT"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Group for data analysts
resource "aws_iam_group" "analysts" {
  count = var.create_analyst_policy ? 1 : 0
  name  = "${var.project_name}-${var.environment}-analysts"
}

# Attach analyst policy to analyst group
resource "aws_iam_group_policy_attachment" "analyst_policy_attachment" {
  count      = var.create_analyst_policy ? 1 : 0
  group      = aws_iam_group.analysts[0].name
  policy_arn = aws_iam_policy.analyst_policy[0].arn
}
