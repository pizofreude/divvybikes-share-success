# Airflow Setup for Divvy Bikes Data Engineering Project

This directory contains the complete Apache Airflow setup for orchestrating the Divvy Bikes data pipeline. The setup uses Docker Compose for easy deployment and includes all necessary configurations for AWS integration and Redshift connectivity.

## 🏗️ Architecture Overview

```
Airflow Pipeline Architecture
├── Data Sources
│   └── Public Divvy S3 Bucket (divvy-tripdata)
├── Airflow Orchestration
│   ├── Data Ingestion DAG
│   ├── Data Quality Checks
│   └── Monitoring & Alerting
├── Data Lake (S3)
│   ├── Bronze Layer (Raw Data)
│   ├── Silver Layer (Cleaned Data)
│   └── Gold Layer (Analytics-Ready)
└── Data Warehouse
    └── Redshift Serverless
```

## 📁 Directory Structure

```
airflow/
├── dags/                          # Airflow DAGs
│   ├── divvy_data_ingestion.py    # Main data ingestion pipeline
│   └── test_divvy_connections.py  # Connectivity test DAG
├── logs/                          # Airflow execution logs
├── plugins/                       # Custom Airflow plugins
├── config/                        # Airflow configuration files
├── scripts/                       # Helper scripts
│   ├── setup_connections.py       # Airflow connections setup
│   ├── setup_variables.py         # Airflow variables setup
│   └── start_airflow.sh           # Complete startup script
├── docker-compose.yml             # Docker Compose configuration
├── Dockerfile                     # Custom Airflow image
├── requirements.txt               # Python dependencies
├── .env                          # Environment variables
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed and running
2. **AWS credentials** configured (via AWS CLI, environment variables, or IAM roles)
3. **Infrastructure deployed** - Ensure your Terraform infrastructure is deployed:
   ```bash
   cd ../terraform
   make deploy-all
   ```

### Step 1: Initialize Redshift Database

Before starting Airflow, initialize your Redshift database with the generated schema:

1. Connect to your Redshift database using your preferred SQL client:
   - **Endpoint**: Use the endpoint from your Terraform outputs
   - **Database**: `divvy`
   - **Username**: `admin`
   - **Password**: Use the password you set in your `.env` file

2. Run the initialization script:
   ```sql
   -- Copy and execute the contents of:
   -- ../terraform/modules/compute/generated/init_database.sql
   ```

### Step 2: Start Airflow

Run the automated setup script:

```bash
cd airflow
chmod +x start_airflow.sh
./start_airflow.sh
```

This script will:
- Initialize the Airflow database
- Start all Airflow services
- Configure connections and variables
- Verify the setup

### Step 3: Access Airflow UI

1. Open your browser and navigate to: **http://localhost:8080**
2. Login with:
   - **Username**: `admin`
   - **Password**: `divvy2024`

### Step 4: Test Connectivity

1. In the Airflow UI, enable the `test_divvy_connections` DAG
2. Trigger it manually to verify all connections work
3. Check the logs to ensure all tests pass

### Step 5: Run Data Ingestion

1. Enable the `divvy_data_ingestion` DAG
2. Trigger it manually for the first run
3. Monitor progress in the Graph or Tree view

## 📋 Available DAGs

### 1. `divvy_data_ingestion`
**Main data ingestion pipeline** that downloads historical Divvy bike data and stores it in the Bronze layer.

**Features:**
- Downloads monthly data for 2023 and 2024
- Validates source data availability
- Implements incremental loading (skips existing files)
- Performs data quality checks
- Generates ingestion summaries

**Schedule**: Daily (checks for new data)
**Runtime**: ~30-60 minutes (depending on data size)

### 2. `test_divvy_connections`
**Connectivity test suite** that verifies all components are properly configured.

**Tests:**
- AWS S3 connection and bucket access
- Redshift connection and schema validation
- Airflow variables configuration
- Public data source access

**Schedule**: Manual trigger only
**Runtime**: ~2-5 minutes

## 🔧 Configuration

### Environment Variables (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `AIRFLOW_UID` | Airflow user ID | `50000` |
| `AWS_DEFAULT_REGION` | AWS region | `ap-southeast-2` |
| `BRONZE_BUCKET` | Bronze layer bucket | `divvybikes-dev-bronze-96wb3c9c` |
| `SILVER_BUCKET` | Silver layer bucket | `divvybikes-dev-silver-96wb3c9c` |
| `GOLD_BUCKET` | Gold layer bucket | `divvybikes-dev-gold-96wb3c9c` |

### Airflow Connections

| Connection ID | Type | Description |
|---------------|------|-------------|
| `aws_default` | AWS | AWS services connection |
| `redshift_default` | Redshift | Redshift Serverless connection |
| `postgres_default` | PostgreSQL | Airflow metadata database |

### Airflow Variables

| Variable | Description | Value |
|----------|-------------|-------|
| `bronze_bucket` | Bronze layer S3 bucket | `divvybikes-dev-bronze-96wb3c9c` |
| `silver_bucket` | Silver layer S3 bucket | `divvybikes-dev-silver-96wb3c9c` |
| `gold_bucket` | Gold layer S3 bucket | `divvybikes-dev-gold-96wb3c9c` |
| `divvy_source_bucket` | Public source bucket | `divvy-tripdata` |
| `data_years_to_process` | Years to process | `2023,2024` |

## 🔍 Monitoring & Troubleshooting

### Viewing Logs

```bash
# View all services
docker-compose logs

# View specific service
docker-compose logs airflow-webserver
docker-compose logs airflow-scheduler

# Follow logs in real-time
docker-compose logs -f airflow-scheduler
```

### Common Issues

#### 1. DAG Not Appearing
- Check DAG file syntax: `python dags/divvy_data_ingestion.py`
- Verify file permissions: `chmod 755 dags/*.py`
- Check scheduler logs: `docker-compose logs airflow-scheduler`

#### 2. AWS Connection Issues
- Verify AWS credentials: `aws sts get-caller-identity`
- Check connection configuration in Airflow UI
- Ensure IAM roles have proper permissions

#### 3. Redshift Connection Issues
- Test connectivity: `telnet divvybikes-dev.864899839546.ap-southeast-2.redshift-serverless.amazonaws.com 5439`
- Verify Redshift is running in AWS console
- Check security group rules for port 5439

#### 4. Out of Memory
- Increase Docker memory allocation (8GB+ recommended)
- Reduce parallel tasks in DAG configuration
- Monitor resource usage: `docker stats`

### Health Checks

```bash
# Check all services status
docker-compose ps

# Check webserver health
curl http://localhost:8080/health

# Check scheduler health  
docker-compose exec airflow-scheduler airflow jobs check --job-type SchedulerJob
```

## 🛠️ Development & Customization

### Adding New DAGs

1. Create your DAG file in the `dags/` directory
2. Follow the existing DAG patterns for consistency
3. Include proper documentation and logging
4. Test locally before deploying

### Custom Dependencies

Add Python packages to `requirements.txt` and rebuild:

```bash
# Add package to requirements.txt
echo "your-package==1.0.0" >> requirements.txt

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

### Environment-Specific Configuration

For different environments (dev/staging/prod), modify the `.env` file:

```bash
# Development
cp .env.dev .env

# Production
cp .env.prod .env
```

## 📊 Performance Optimization

### Resource Allocation

Recommended Docker resource allocation:
- **Memory**: 8GB minimum, 16GB recommended
- **CPU**: 4 cores minimum
- **Disk**: 50GB for logs and temporary data

### DAG Configuration

Optimize DAG performance:
- Set appropriate `max_active_runs` (default: 1)
- Configure `max_active_tasks` per DAG (default: 16)
- Use `depends_on_past=False` for independent runs
- Implement proper error handling and retries

### Database Performance

For production workloads:
- Use external PostgreSQL instead of containerized
- Configure connection pooling
- Monitor database size and performance

## 🔄 Backup & Recovery

### Backup Important Data

```bash
# Backup Airflow metadata
docker-compose exec postgres pg_dump -U airflow airflow > airflow_backup.sql

# Backup DAGs and configuration
tar -czf airflow_config_backup.tar.gz dags/ plugins/ config/ .env
```

### Recovery

```bash
# Restore Airflow metadata
docker-compose exec -T postgres psql -U airflow airflow < airflow_backup.sql

# Restore configuration
tar -xzf airflow_config_backup.tar.gz
```

## 📈 Scaling Considerations

### Horizontal Scaling

For larger workloads:
- Use external Redis cluster for Celery backend
- Deploy multiple worker nodes
- Use Kubernetes for container orchestration
- Implement proper monitoring with Prometheus/Grafana

### Vertical Scaling

For single-node improvements:
- Increase Docker resource limits
- Use SSD storage for better I/O
- Optimize PostgreSQL configuration
- Monitor and tune garbage collection

## 🔒 Security Best Practices

1. **Secrets Management**
   - Use Airflow's built-in secrets backend
   - Consider AWS Secrets Manager integration
   - Never commit passwords to version control

2. **Network Security**
   - Use VPC endpoints for AWS services
   - Implement proper firewall rules
   - Enable HTTPS for web UI in production

3. **Access Control**
   - Configure RBAC in Airflow
   - Use IAM roles instead of access keys
   - Implement proper user authentication

## 📞 Support & Troubleshooting

### Getting Help

1. **Check Logs**: Always start with task and scheduler logs
2. **Airflow Documentation**: https://airflow.apache.org/docs/
3. **AWS Documentation**: For service-specific issues
4. **Community Forums**: Stack Overflow, Airflow Slack

### Useful Commands

```bash
# Restart all services
docker-compose restart

# Rebuild after configuration changes
docker-compose down && docker-compose up --build -d

# Access Airflow CLI
docker-compose exec airflow-webserver airflow --help

# Check DAG status
docker-compose exec airflow-webserver airflow dags list

# Test specific task
docker-compose exec airflow-webserver airflow tasks test divvy_data_ingestion validate_aws_connectivity 2025-07-15
```

---

## 🎯 Next Steps

After successful Airflow setup:

1. **Verify Data Ingestion**: Check Bronze layer S3 buckets for data
2. **Set up Data Transformation**: Implement Silver and Gold layer processing
3. **Create Analytics Dashboards**: Connect BI tools to Redshift
4. **Implement Monitoring**: Set up alerting for pipeline failures
5. **Optimize Performance**: Monitor and tune based on actual usage

Happy data engineering! 🚀
