#!/bin/bash
# Destroy Compute Infrastructure - Divvy Bikes Project
# This script safely destroys compute infrastructure while preserving data

set -e  # Exit on any error

echo "🗑️  Destroying Compute Infrastructure for Divvy Bikes Project"
echo "============================================================"
echo ""
echo "⚠️  WARNING: This will destroy all compute resources (Redshift Serverless)"
echo "   📊 Data in S3 buckets will be preserved"
echo "   🔄 You can recreate compute resources later without data loss"
echo ""

# Ask for confirmation
read -p "❓ Are you sure you want to destroy compute infrastructure? (y/n): " confirm_destroy
if [[ ! $confirm_destroy =~ ^[Yy]$ ]]; then
    echo "❌ Destroy operation cancelled"
    exit 0
fi

# Change to compute environment directory
cd "$(dirname "$0")/../environments/compute"

# Check if compute infrastructure exists
if [ ! -f "terraform.tfstate" ]; then
    echo "ℹ️  No compute infrastructure found to destroy"
    exit 0
fi

# Plan the destruction
echo "📋 Creating destruction plan..."
terraform plan -destroy -var-file="terraform.tfvars" -out="destroy.tfplan"

# Show what will be destroyed
echo ""
echo "🔍 Resources to be destroyed:"
terraform show destroy.tfplan

# Final confirmation
echo ""
read -p "⚠️  Final confirmation - destroy compute infrastructure? (type 'destroy' to confirm): " final_confirm
if [[ $final_confirm != "destroy" ]]; then
    echo "❌ Destroy operation cancelled"
    exit 0
fi

# Apply the destruction
echo "🗑️  Destroying compute infrastructure..."
terraform apply destroy.tfplan

echo ""
echo "✅ Compute infrastructure destroyed successfully!"
echo ""
echo "💡 To recreate:"
echo "   ./apply-compute.sh"
echo ""
echo "📊 Data preservation status:"
echo "   ✅ S3 buckets and data preserved"
echo "   ✅ Networking infrastructure preserved"
echo "   ✅ IAM roles and policies preserved"
echo ""
