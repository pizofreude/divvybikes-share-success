#!/bin/bash
# Helper script to load environment variables for Terraform operations
# Source this script before running terraform commands: source load_env.sh

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    set -a # automatically export all variables
    source .env
    set +a # stop automatically exporting
    echo "✅ Environment variables loaded from .env"
elif [ -f "../.env" ]; then
    echo "Loading environment variables from ../.env file..."
    set -a # automatically export all variables
    source ../.env
    set +a # stop automatically exporting
    echo "✅ Environment variables loaded from ../.env"
else
    echo "❌ .env file not found in current directory or parent directory"
    echo "Please copy .env.template to .env and configure it first"
    echo "Expected locations:"
    echo "  - $(pwd)/.env"
    echo "  - $(pwd)/../.env"
    return 1
fi

# Check that required Terraform variables are set
if [ -z "$TF_VAR_redshift_admin_password" ]; then
    echo "❌ TF_VAR_redshift_admin_password not set"
    echo "Please ensure your .env file includes TF_VAR_redshift_admin_password"
    echo "Example: TF_VAR_redshift_admin_password=your_secure_password"
    return 1
fi

echo "✅ Terraform environment variables ready"
echo "You can now run terraform commands"
