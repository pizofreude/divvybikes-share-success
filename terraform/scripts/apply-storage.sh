#!/bin/bash
# Apply Storage Infrastructure - Divvy Bikes Project
# This script deploys the storage infrastructure (S3 buckets, IAM roles)

set -e  # Exit on any error

echo "🗄️  Deploying Storage Infrastructure for Divvy Bikes Project"
echo "==========================================================="

# Change to storage environment directory
cd "$(dirname "$0")/../environments/storage"

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
else
    echo "📦 Terraform already initialized"
fi

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Creating deployment plan..."
terraform plan -var-file="terraform.tfvars" -out="storage.tfplan"

# Ask for confirmation
echo ""
read -p "🔍 Would you like to review the plan before applying? (y/n): " review_plan
if [[ $review_plan =~ ^[Yy]$ ]]; then
    terraform show storage.tfplan
    echo ""
    read -p "🚀 Proceed with deployment? (y/n): " proceed
    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 0
    fi
fi

# Apply the configuration
echo "🚀 Deploying storage infrastructure..."
terraform apply storage.tfplan

# Show outputs
echo ""
echo "✅ Storage infrastructure deployed successfully!"
echo "📊 Deployment outputs:"
terraform output

# Show bucket information
echo ""
echo "🪣 S3 Buckets created:"
echo "   Check the 'bucket_names' output above for the complete list"

echo ""
echo "🔐 IAM Resources:"
echo "   - Redshift service role created"
echo "   - Airflow user access keys created (check outputs for credentials)"

echo ""
echo "🎯 Next steps:"
echo "   1. Store AWS credentials in your environment or .aws/credentials"
echo "   2. Run ./apply-compute.sh to deploy compute infrastructure"
echo ""
