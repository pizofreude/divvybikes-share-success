# Compute Module

This module creates the compute infrastructure for the Divvy Bikes data engineering project, centered around Redshift Serverless for cost-effective data warehousing.

## Architecture

The compute module provides:

- **Redshift Serverless**: Pay-per-use data warehouse
- **Namespace & Workgroup**: Logical organization and resource management
- **Usage Limits**: Cost control with automatic breach actions
- **VPC Integration**: Secure networking with existing infrastructure
- **Database Initialization**: Automated schema and table creation
- **Airflow Integration**: Connection configuration for data pipelines

## Cost Optimization Features

1. **Serverless Architecture**: Pay only for compute time used (per second billing)
2. **Usage Limits**: Prevent runaway costs with configurable monthly RPU limits
3. **Auto-pause**: Automatically scales to zero when not in use
4. **Optimized Capacity**: Starts with minimal 8 RPUs for small datasets
5. **Enhanced VPC Routing**: Reduces data transfer costs

## Resources Created

| Resource | Purpose | Cost Impact |
|----------|---------|-------------|
| Redshift Namespace | Logical container for databases | Free |
| Redshift Workgroup | Compute configuration | $0.144/RPU-hour when active |
| Usage Limits | Cost control | Free (prevents overruns) |
| CloudWatch Logs | Query monitoring | ~$0.50/GB ingested |
| Generated Scripts | Database initialization | Free |

## Usage

```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "divvybikes"
  environment  = "dev"

  # State file references
  networking_state_path = "../networking/terraform.tfstate"
  storage_state_path    = "../storage/terraform.tfstate"

  # Redshift Configuration
  redshift_admin_username = "admin"
  redshift_admin_password = var.redshift_admin_password
  redshift_database_name  = "divvy"

  # Capacity & Cost Control
  base_capacity_rpus        = 8
  monthly_usage_limit_rpus  = 100
  enable_usage_limits       = true
  usage_limit_breach_action = "log"

  # Network & Security
  publicly_accessible = true  # For local Docker Airflow access
  enable_logging      = true

  common_tags = {
    Project     = "DivvyBikes"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Configuration Parameters

### Capacity Settings
- **base_capacity_rpus**: Starting compute capacity (default: 8 RPUs)
- **monthly_usage_limit_rpus**: Maximum monthly compute units (default: 100)
- **usage_limit_breach_action**: Action when limit exceeded (`log`, `emit-metric`, `deactivate`)

### Security Settings
- **publicly_accessible**: Enable public access for local development
- **enhanced_vpc_routing**: Force traffic through VPC (security + cost optimization)
- **kms_key_id**: Optional KMS key for encryption

### Logging & Monitoring
- **enable_logging**: Enable CloudWatch logging
- **log_exports**: Types of logs to export (`userlog`, `connectionlog`, `useractivitylog`)
- **log_retention_days**: CloudWatch log retention period

## Dependencies

This module requires:

1. **Networking Module**: Must be deployed first to provide VPC and security groups
2. **Storage Module**: Must be deployed first to provide S3 buckets and IAM roles

The module uses Terraform remote state to reference outputs from these dependencies.

## Outputs

### Connection Information
- `redshift_endpoint`: Host and port for connections
- `redshift_jdbc_url`: JDBC connection string
- `redshift_connection_string`: PostgreSQL-style connection string

### Resource Information
- `redshift_namespace_name`: Namespace identifier
- `redshift_workgroup_name`: Workgroup identifier
- `redshift_database_name`: Default database name

### Generated Files
- `init_database_script_path`: SQL script for schema creation
- `airflow_connection_config_path`: JSON config for Airflow connections

## Generated Files

The module creates two important files in the `generated/` directory:

### 1. Database Initialization Script (`init_database.sql`)
```sql
-- Creates schemas for medallion architecture
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Creates external schemas for S3 access
CREATE EXTERNAL SCHEMA bronze_external
FROM DATA CATALOG DATABASE 'divvy_bronze'
IAM_ROLE 'arn:aws:iam::ACCOUNT:role/redshift-role';
```

### 2. Airflow Connection Config (`airflow_redshift_connection.json`)
```json
{
  "conn_id": "redshift_default",
  "conn_type": "redshift",
  "host": "workgroup.region.redshift-serverless.amazonaws.com",
  "port": 5439,
  "schema": "divvy",
  "login": "admin"
}
```

## Cost Estimation

Based on usage patterns:

| Usage Pattern | Monthly RPUs | Est. Cost (AUD) | Use Case |
|---------------|--------------|-----------------|----------|
| Minimal Development | 20 RPUs | $2.88 | Testing queries occasionally |
| Active Development | 50 RPUs | $7.20 | Daily development work |
| Production (Small) | 100 RPUs | $14.40 | Regular data processing |

**Cost Formula**: RPUs × $0.144 × Hours Active = Cost

## Security Features

1. **VPC Integration**: Private subnets with security groups
2. **IAM Integration**: Role-based access to S3 buckets
3. **Encryption**: At-rest and in-transit encryption
4. **Activity Logging**: User activity and connection logging
5. **Parameter Hardening**: Secure default configurations

## Development vs Production

### Development Configuration
```hcl
base_capacity_rpus        = 8
monthly_usage_limit_rpus  = 50
publicly_accessible       = true
usage_limit_breach_action = "log"
```

### Production Configuration
```hcl
base_capacity_rpus        = 16
monthly_usage_limit_rpus  = 500
publicly_accessible       = false
usage_limit_breach_action = "deactivate"
kms_key_id               = "arn:aws:kms:region:account:key/key-id"
```

## Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Check security group allows port 5439
   - Verify public accessibility setting
   - Confirm networking state file exists

2. **Access Denied to S3**
   - Verify IAM role permissions
   - Check S3 bucket policies
   - Ensure storage state file is available

3. **Usage Limit Reached**
   - Check CloudWatch metrics
   - Increase monthly limit if needed
   - Review breach action setting

### Monitoring Commands
```bash
# Check Redshift status
aws redshift-serverless describe-workgroup --workgroup-name divvybikes-dev

# Monitor usage
aws redshift-serverless describe-usage-limits --workgroup-name divvybikes-dev

# View recent queries
aws logs filter-log-events --log-group-name /aws/redshift-serverless/divvybikes-dev
```

## Integration with Data Pipeline

This module is designed to integrate seamlessly with:

1. **Airflow DAGs**: Use generated connection config
2. **dbt**: Connect using JDBC URL output
3. **Business Intelligence**: Connect via standard PostgreSQL drivers
4. **Data Catalogs**: Integrated with AWS Glue for metadata

## Notes

- Redshift Serverless automatically scales based on workload
- Billing is per second with 60-second minimum
- Enhanced VPC routing is enabled for security and cost optimization
- Module includes comprehensive tagging for cost allocation
- Compatible with both local development and production environments
