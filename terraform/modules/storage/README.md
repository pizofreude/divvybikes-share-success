# Storage Module

This module creates S3 buckets for the medallion architecture (Bronze, Silver, Gold layers) with comprehensive cost optimization features.

## Resources Created

### S3 Buckets

- **Bronze Bucket**: Raw ingested data from Divvy bike share system
- **Silver Bucket**: Cleaned and transformed data ready for analysis
- **Gold Bucket**: Business-ready aggregated data and analytics
- **Terraform State Bucket**: Optional bucket for storing Terraform state files

### Security Features

- **Encryption**: SSE-S3 encryption enabled for all buckets
- **Versioning**: Enabled on all buckets to protect against accidental deletions
- **Public Access Block**: All public access blocked for security
- **Bucket Key**: Enabled to reduce KMS costs

### Cost Optimization Features

#### Intelligent Tiering

- **Bronze Layer**: Archive after 90 days, Deep Archive after 180 days
- **Silver Layer**: Archive after 180 days, Deep Archive after 365 days
- **Gold Layer**: Standard-IA after 30 days, Glacier after 90 days

#### Lifecycle Management

- **Automatic Storage Class Transitions**: Based on access patterns
- **Version Management**: Automatic cleanup of old versions
- **Multipart Upload Cleanup**: Removes incomplete uploads after 7 days

#### Data Retention Policies

- **Bronze**: 1-year version retention (raw data can be re-ingested)
- **Silver**: 2-year version retention (processed data valuable)
- **Gold**: 7-year version retention (business-critical data)

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  project_name = "divvybikes"
  environment  = "dev"

  # Optional: Create Terraform state bucket
  create_terraform_state_bucket = true

  # Customize retention policies if needed
  bronze_archive_days      = 90
  silver_archive_days      = 180
  gold_standard_ia_days    = 30

  common_tags = {
    Project     = "divvybikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
  }
}
```

## Outputs

### Individual Bucket Outputs

- `bronze_bucket_id`, `silver_bucket_id`, `gold_bucket_id`: Bucket identifiers
- `bronze_bucket_arn`, `silver_bucket_arn`, `gold_bucket_arn`: Bucket ARNs for IAM policies

### Consolidated Outputs

- `data_buckets`: Complete bucket information for Airflow DAGs
- `bucket_names`: Simple bucket names for configuration files

## File Organization

### Recommended S3 Structure

```text
bronze-bucket/
├── divvy-tripdata/
│   ├── year=2024/
│   │   ├── month=01/
│   │   │   └── 202401-divvy-tripdata.csv
│   │   ├── month=02/
│   │   │   └── 202402-divvy-tripdata.csv
│   │   └── ...
│   └── year=2025/
│       └── month=01/
│           └── 202501-divvy-tripdata.csv
└── station-data/
    └── stations.json

silver-bucket/
├── divvy-trips/
│   ├── year=2024/
│   │   ├── month=01/
│   │   │   └── cleaned-trips.parquet
│   │   └── ...
│   └── ...
└── station-metadata/
    └── stations-cleaned.parquet

gold-bucket/
├── analytics/
│   ├── member-vs-casual/
│   │   └── usage-patterns.parquet
│   ├── station-popularity/
│   │   └── station-rankings.parquet
│   └── temporal-analysis/
│       └── time-series.parquet
└── reports/
    └── monthly-summaries/
        └── 2024-01-summary.parquet
```

## Cost Estimation

For a 2GB dataset with typical usage patterns:

| Storage Class | Estimated Usage | Monthly Cost (AUD) |
|---------------|----------------|-------------------|
| Standard | 500MB (active data) | ~$0.012 |
| Standard-IA | 800MB (less frequent) | ~$0.012 |
| Intelligent-Tiering | 700MB (variable access) | ~$0.012 |
| **Total Storage** | **2GB** | **~$0.036/month** |
| Requests (PUT/GET) | ~1000/month | ~$0.006 |
| **Total Estimated** | | **~$0.05/month** |

## Security Considerations

- All buckets have public access blocked by default
- Encryption at rest using SSE-S3
- Versioning enabled to protect against data loss
- Lifecycle policies prevent indefinite storage growth
- IAM policies should follow least privilege principle

## Best Practices

1. **Use Parquet Format**: For Silver and Gold layers to optimize storage and query performance
2. **Partition Data**: Use year/month partitions for time-series data
3. **Monitor Costs**: Use AWS Cost Explorer to track storage costs
4. **Regular Cleanup**: Lifecycle policies handle this automatically
5. **Access Patterns**: Design queries to minimize data transfer costs
