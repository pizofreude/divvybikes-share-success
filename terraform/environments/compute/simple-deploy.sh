#!/bin/bash
# Simple compute deployment script
# Run from terraform/environments/compute directory

echo "Starting compute deployment..."

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "Error: Please run this script from terraform/environments/compute directory"
    exit 1
fi

# Check prerequisites
if [ ! -f "../networking/terraform.tfstate" ]; then
    echo "Error: Networking infrastructure not found"
    echo "Please run 'make deploy-networking' first"
    exit 1
fi

if [ ! -f "../storage/terraform.tfstate" ]; then
    echo "Error: Storage infrastructure not found"
    echo "Please run 'make deploy-storage' first"
    exit 1
fi

echo "Prerequisites check passed"

# Initialize terraform
terraform init

# Set password if not set
if [ -z "$TF_VAR_redshift_admin_password" ]; then
    echo "Error: TF_VAR_redshift_admin_password environment variable not set"
    echo "Please set it in your environment or source your .env file"
    echo "Example: export TF_VAR_redshift_admin_password='your_secure_password'"
    exit 1
fi

# Validate configuration
terraform validate

# Plan
terraform plan -var-file="terraform.tfvars" -out="compute.tfplan"

# Apply
terraform apply -auto-approve compute.tfplan

# Show outputs
terraform output
