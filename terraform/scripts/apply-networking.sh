#!/bin/bash
# Apply Networking Infrastructure - Divvy Bikes Project
# This script deploys the networking infrastructure (VPC, subnets, security groups)

set -e  # Exit on any error

echo "🌐 Deploying Networking Infrastructure for Divvy Bikes Project"
echo "============================================================"

# Change to networking environment directory
cd "$(dirname "$0")/../environments/networking"

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
terraform plan -var-file="terraform.tfvars" -out="networking.tfplan"

# Ask for confirmation
echo ""
read -p "🔍 Would you like to review the plan before applying? (y/n): " review_plan
if [[ $review_plan =~ ^[Yy]$ ]]; then
    terraform show networking.tfplan
    echo ""
    read -p "🚀 Proceed with deployment? (y/n): " proceed
    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 0
    fi
fi

# Apply the configuration
echo "🚀 Deploying networking infrastructure..."
terraform apply networking.tfplan

# Show outputs
echo ""
echo "✅ Networking infrastructure deployed successfully!"
echo "📊 Deployment outputs:"
terraform output

echo ""
echo "🎯 Next steps:"
echo "   1. Run ./apply-storage.sh to deploy storage infrastructure"
echo "   2. Run ./apply-compute.sh to deploy compute infrastructure"
echo ""
