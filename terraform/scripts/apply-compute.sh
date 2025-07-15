#!/bin/bash
# Apply Compute Infrastructure - Divvy Bikes Project
# This script deploys the compute infrastructure (Redshift Serverless)

set -e  # Exit on any error

echo "💻 Deploying Compute Infrastructure for Divvy Bikes Project"
echo "=========================================================="

# Check if networking and storage are deployed
echo "🔍 Checking prerequisites..."

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check networking state
NETWORKING_STATE="${SCRIPT_DIR}/../environments/networking/terraform.tfstate"
if [ ! -f "$NETWORKING_STATE" ]; then
    echo "❌ Networking infrastructure not found. Please run 'make deploy-networking' first"
    echo "   Looking for: $NETWORKING_STATE"
    exit 1
fi

# Check storage state  
STORAGE_STATE="${SCRIPT_DIR}/../environments/storage/terraform.tfstate"
if [ ! -f "$STORAGE_STATE" ]; then
    echo "❌ Storage infrastructure not found. Please run 'make deploy-storage' first"
    echo "   Looking for: $STORAGE_STATE"
    exit 1
fi

echo "✅ Prerequisites met"

# Change to compute environment directory
cd "$(dirname "$0")/../environments/compute"

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
else
    echo "📦 Terraform already initialized"
fi

# Check if password is set, if not prompt for it
if [ -z "$TF_VAR_redshift_admin_password" ]; then
    echo "🔑 Redshift admin password not set as environment variable"
    read -s -p "Enter Redshift admin password: " REDSHIFT_PASSWORD
    echo ""
    export TF_VAR_redshift_admin_password="$REDSHIFT_PASSWORD"
fi

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Creating deployment plan..."
terraform plan -var-file="terraform.tfvars" -out="compute.tfplan"

# Ask for confirmation
echo ""
read -p "🔍 Would you like to review the plan before applying? (y/n): " review_plan
if [[ $review_plan =~ ^[Yy]$ ]]; then
    terraform show compute.tfplan
    echo ""
    read -p "🚀 Proceed with deployment? (y/n): " proceed
    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 0
    fi
fi

# Apply the configuration
echo "🚀 Deploying compute infrastructure..."
terraform apply compute.tfplan

# Show outputs
echo ""
echo "✅ Compute infrastructure deployed successfully!"
echo "📊 Deployment outputs:"
terraform output

# Show connection information
echo ""
echo "🔗 Redshift Connection Information:"
echo "   Endpoint: $(terraform output -raw redshift_endpoint | jq -r '.address'):$(terraform output -raw redshift_endpoint | jq -r '.port')"
echo "   Database: $(terraform output -raw redshift_database_name)"
echo "   Username: $(terraform output -raw redshift_admin_username)"

echo ""
echo "💰 Cost Estimate:"
terraform output -json estimated_monthly_cost | jq -r '"   Max Monthly Cost: $\(.max_monthly_cost_usd) USD (\(.max_monthly_cost_aud) AUD)"'

echo ""
echo "🎯 Next steps:"
echo "   1. Configure Airflow connections using generated configuration files"
echo "   2. Test Redshift connection"
echo "   3. Set up Docker Airflow environment"
echo ""
