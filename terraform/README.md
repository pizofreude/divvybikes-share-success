# Divvy Bikes Terraform Infrastructure

This directory contains the complete Infrastructure as Code (IaC) for the Divvy Bikes data engineering project, implementing a cost-optimized, secure, and scalable architecture in AWS.

## 🏗️ Architecture Overview

The infrastructure follows a **modular design** with **separation of concerns**:

- **Medallion Data Lake**: Bronze (raw) → Silver (cleaned) → Gold (business-ready)
- **Serverless Computing**: Redshift Serverless for pay-per-use analytics
- **Local Orchestration**: Docker-based Airflow for cost optimization
- **Network Isolation**: VPC with private subnets and security groups
- **Cost Optimization**: Intelligent S3 tiering, no NAT gateways, minimal resources

## 📁 Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, security groups
│   ├── storage/               # S3 buckets with lifecycle policies
│   ├── compute/               # Redshift Serverless
│   └── iam/                   # IAM roles and policies
├── environments/              # Environment-specific deployments
│   ├── networking/            # Deploy networking infrastructure
│   ├── storage/               # Deploy storage infrastructure
│   └── compute/               # Deploy compute infrastructure
├── scripts/                   # Automation scripts
│   ├── apply-networking.sh    # Deploy networking
│   ├── apply-storage.sh       # Deploy storage
│   ├── apply-compute.sh       # Deploy compute
│   └── destroy-compute.sh     # Destroy compute (preserves data)
├── Makefile                   # Convenient automation commands
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** for Airflow (optional)
4. **Make** for convenience commands

### Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Deploy everything in order
make deploy-all

# Or deploy step by step
make deploy-networking
make deploy-storage
make deploy-compute
```

### Start Development Environment

```bash
# Set up and start Airflow
make setup-airflow
make start-airflow

# Check status
make status
```

## 💰 Cost Optimization Features

| Feature | Monthly Savings | Description |
|---------|----------------|-------------|
| **No NAT Gateway** | ~$45 AUD | Uses VPC endpoints for S3 access |
| **Local Airflow** | ~$30 AUD | Docker instead of EC2 instance |
| **Intelligent Tiering** | 20-40% | Automatic S3 storage optimization |
| **Redshift Serverless** | Pay-per-use | No idle costs, automatic scaling |

**Estimated Monthly Cost**: $5-15 AUD (depending on usage)

## 🔧 Available Commands

### Infrastructure Management
```bash
make deploy-networking    # Deploy VPC and networking
make deploy-storage      # Deploy S3 buckets and IAM
make deploy-compute      # Deploy Redshift Serverless
make deploy-all          # Deploy everything in order
```

### Airflow Management
```bash
make setup-airflow       # Create Airflow directory structure
make start-airflow       # Start Airflow containers
make stop-airflow        # Stop Airflow containers
make restart-airflow     # Restart Airflow
```

### Status and Information
```bash
make status              # Check infrastructure status
make cost-estimate       # Show cost estimates
make aws-check          # Verify AWS credentials
make s3-list            # List project S3 buckets
```

### Cleanup
```bash
make destroy-compute     # Destroy compute (preserves data)
make destroy-all         # ⚠️ Destroy everything including data
```

## 🏛️ Module Details

### Networking Module
- **VPC**: 10.0.0.0/16 with DNS resolution
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24 (for Redshift)
- **Public Subnets**: Optional, disabled by default
- **S3 VPC Endpoint**: Free gateway endpoint for S3 access
- **Security Groups**: Redshift (port 5439) and general purpose

### Storage Module
- **Bronze Bucket**: Raw Divvy data with 1-year retention
- **Silver Bucket**: Cleaned data with 2-year retention  
- **Gold Bucket**: Business data with 7-year retention
- **Intelligent Tiering**: Automatic cost optimization
- **Encryption**: SSE-S3 with bucket keys
- **Security**: Public access blocked, HTTPS-only policies

### Compute Module
- **Redshift Serverless**: 8 RPUs base capacity
- **Usage Limits**: Configurable monthly RPU-hour limits
- **Network**: Deployed in private subnets
- **Security**: VPC security groups, encryption at rest
- **Integration**: Service role for S3 access

### IAM Module
- **Redshift Role**: S3 access for data loading
- **Airflow User**: Programmatic access for local Docker
- **Analyst Group**: Read-only access to Silver/Gold data
- **Policies**: Least privilege access patterns

## 🔐 Security Features

1. **Network Isolation**: Private subnets for data resources
2. **Encryption**: All data encrypted at rest and in transit
3. **Access Control**: IAM roles with least privilege
4. **Public Access**: Blocked on all S3 buckets
5. **HTTPS-Only**: Bucket policies enforce secure transport
6. **Versioning**: Enabled for data protection

## 🛠️ Development Workflow

### Daily Development
```bash
# Start your day
make start-airflow
make status

# Work on data pipelines
# (Access Airflow at http://localhost:8080)

# End your day (save costs)
make stop-airflow
# Optional: make destroy-compute
```

### Cost Control
```bash
# Destroy compute when not actively developing
make destroy-compute

# Recreate when needed
make deploy-compute

# Monitor costs
make cost-estimate
```

## 📊 Outputs and Integration

### Environment Outputs
Each environment provides outputs for integration:

- **Networking**: VPC ID, subnet IDs, security groups
- **Storage**: Bucket names, ARNs, IAM roles
- **Compute**: Endpoint, connection strings, credentials

### Airflow Integration
Generated configuration files for Airflow connections:
- `../airflow/config/redshift_connection.json`
- `../airflow/config/s3_buckets.json`

## 🔍 Troubleshooting

### Common Issues

1. **AWS Credentials**: Run `make aws-check`
2. **Terraform State**: Check `*.tfstate` files exist
3. **Docker Issues**: Verify Docker is running for Airflow
4. **Permissions**: Ensure IAM user has sufficient permissions

### State Management

Each environment has its own state file:
- `environments/networking/terraform.tfstate`
- `environments/storage/terraform.tfstate`
- `environments/compute/terraform.tfstate`

### Recovery

If deployment fails:
```bash
# Re-initialize and try again
make init-all
make validate-all
make deploy-all
```

## 🎯 Next Steps

1. **Deploy Infrastructure**: `make deploy-all`
2. **Configure Airflow**: Set up Docker Compose and credentials
3. **Create Data Pipelines**: Develop DAGs for Divvy data processing
4. **Test Analytics**: Connect to Redshift and run queries
5. **Monitor Costs**: Use `make cost-estimate` regularly

## 📝 Notes

- Designed for **ap-southeast-2** (Sydney) region
- Optimized for **development and learning** environments
- **Production**: Review security settings and cost controls
- **Scaling**: Adjust Redshift capacity and storage lifecycle policies as needed

---

**🎉 Happy Data Engineering!** 

For issues or questions, refer to the terraform_plan.md in the .context directory.
