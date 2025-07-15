# IAM Module

This module creates IAM roles, policies, and users for secure access to AWS resources in the Divvy Bikes data engineering project.

## Resources Created

### Service Roles

- **Redshift Role**: IAM role for Redshift Serverless to access S3 buckets
- **Airflow Role**: Optional IAM role for Airflow (when using assume role authentication)

### User Accounts

- **Airflow User**: IAM user for local Docker Airflow with programmatic access
- **Analyst Group**: Optional IAM group for data analysts with read-only access

### Policies

- **Redshift S3 Policy**: Allows Redshift to read data from S3 buckets
- **Airflow Policy**: Full access to S3 and Redshift for data operations
- **Analyst Policy**: Read-only access to Silver and Gold layer data

## Security Design

### Principle of Least Privilege

Each role and user is granted only the minimum permissions required for their function:

- **Redshift**: Read-only access to S3 buckets for data loading
- **Airflow**: Full data pipeline access (read/write S3, execute Redshift queries)
- **Analysts**: Read-only access to processed data layers only

### Access Patterns

#### Airflow Authentication Options

1. **IAM User with Access Keys** (Default)
   - Best for local Docker Airflow development
   - Simple setup with AWS credentials
   - Suitable for development environments

2. **IAM Role with Assume Role** (Optional)
   - More secure for production environments
   - Requires additional configuration in Airflow
   - Better for audit and compliance

#### Redshift Access

- Service role attached to Redshift Serverless
- Enables Redshift to read data from S3 without additional credentials
- Automatically assumed by Redshift service

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project_name = "divvybikes"
  environment  = "dev"

  # S3 bucket ARNs from storage module
  s3_bucket_arns = [
    module.storage.bronze_bucket_arn,
    module.storage.silver_bucket_arn,
    module.storage.gold_bucket_arn
  ]

  # Analyst access to processed data only
  analyst_s3_bucket_arns = [
    module.storage.silver_bucket_arn,
    module.storage.gold_bucket_arn
  ]

  # Create user for local Airflow development
  create_airflow_user = true
  
  # Optional: Create analyst resources
  create_analyst_policy = false

  common_tags = {
    Project     = "divvybikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
  }
}
```

## Outputs

### For Redshift Configuration

- `redshift_role_arn`: Use this in Redshift Serverless configuration
- `redshift_role_name`: Role name for reference

### For Airflow Configuration

- `airflow_access_key_id`: AWS Access Key ID for Airflow (sensitive)
- `airflow_secret_access_key`: AWS Secret Access Key for Airflow (sensitive)
- `airflow_user_arn`: User ARN for logging and auditing

### For Team Management

- `analysts_group_name`: IAM group for adding analyst users
- `analyst_policy_arn`: Policy ARN for custom role assignments

## Security Best Practices

### Access Key Management

1. **Rotation**: Regularly rotate access keys for the Airflow user
2. **Environment Variables**: Store credentials as environment variables, not in code
3. **Encryption**: Use encrypted storage for sensitive credentials

### Monitoring and Auditing

1. **CloudTrail**: Enable CloudTrail to monitor API calls
2. **Access Logging**: Enable S3 access logging for audit trails
3. **Regular Reviews**: Periodically review and clean up unused credentials

### Network Security

1. **VPC Endpoints**: Use VPC endpoints for S3 access to avoid internet routing
2. **Security Groups**: Restrict Redshift access to necessary sources only
3. **Private Subnets**: Deploy Redshift in private subnets

## Environment Configuration

### Local Development Setup

1. **AWS CLI Configuration**:
   ```bash
   aws configure set aws_access_key_id <airflow_access_key_id>
   aws configure set aws_secret_access_key <airflow_secret_access_key>
   aws configure set region ap-southeast-2
   ```

2. **Docker Environment Variables**:
   ```bash
   export AWS_ACCESS_KEY_ID=<airflow_access_key_id>
   export AWS_SECRET_ACCESS_KEY=<airflow_secret_access_key>
   export AWS_DEFAULT_REGION=ap-southeast-2
   ```

3. **Airflow Connections**:
   - Connection ID: `aws_default`
   - Connection Type: `Amazon Web Services`
   - Login: `<airflow_access_key_id>`
   - Password: `<airflow_secret_access_key>`
   - Extra: `{"region_name": "ap-southeast-2"}`

## Cost Considerations

- IAM roles, policies, and users have no direct costs
- Access key usage is free
- Monitor CloudTrail costs if detailed logging is enabled
- S3 access logging may incur minimal storage costs

## Compliance Notes

- All access is logged through CloudTrail when enabled
- Access keys can be rotated without service interruption
- Policies follow AWS Well-Architected Framework security principles
- Role-based access control supports compliance requirements
