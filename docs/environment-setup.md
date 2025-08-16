# Environment Setup Guide

This guide explains how to properly configure environment variables for the Divvy Bikes data engineering project, ensuring no sensitive credentials are hardcoded.

## Quick Setup

1. **Copy environment templates**:
   ```bash
   # In project root
   cp .env.template .env
   
   # In airflow directory
   cd airflow
   cp .env.template .env
   ```

2. **Configure your credentials** in both `.env` files:
   - Set a secure password for `REDSHIFT_ADMIN_PASSWORD`
   - Update other values as needed after infrastructure deployment

3. **Load environment for Terraform operations**:
   ```bash
   # From terraform directory
   
   # Option 1: Bash (Git Bash, WSL, Linux)
   source load_env.sh
   
   # Option 2: PowerShell (Windows)
   . .\load_env.ps1
   
   # Option 3: Command Prompt (Windows)
   load_env.bat
   ```

## Environment Files

### Root `.env` File
Location: `divvybikes-share-success/.env`

This file contains project-wide environment variables, including Terraform variables.

Key variables to configure:
- `REDSHIFT_ADMIN_PASSWORD`: Set a secure password (minimum 8 characters, mixed case, numbers)
  - **Important**: If your password contains special characters (`&`, `$`, `!`, etc.), wrap it in quotes: `"MyPassword&123"`
- `TF_VAR_redshift_admin_password`: Should match `REDSHIFT_ADMIN_PASSWORD` and also be quoted if it contains special characters

### Airflow `.env` File  
Location: `divvybikes-share-success/airflow/.env`

This file contains Airflow-specific environment variables.

Key variables to configure:
- `REDSHIFT_ADMIN_PASSWORD`: Same as root .env file
- After Terraform deployment, update:
  - `REDSHIFT_ENDPOINT`: From terraform output
  - `BRONZE_BUCKET`, `SILVER_BUCKET`, `GOLD_BUCKET`: From terraform output

## Security Best Practices

### What's Fixed
✅ **Removed hardcoded credentials from**:
- `airflow/docker-compose.yml`
- `airflow/start_airflow.sh` 
- `terraform/Makefile`
- `terraform/environments/compute/simple-deploy.sh`
- Documentation files

✅ **Environment variable loading**:
- Docker Compose loads from `.env` file
- Scripts check for required variables
- Helper scripts for environment loading

### What You Should Do
1. **Never commit `.env` files** - they're in `.gitignore`
2. **Use strong passwords** - minimum 8 characters with mixed case, numbers, symbols
3. **Keep credentials secure** - don't share or store in unsecure locations
4. **Rotate credentials** regularly in production environments

## Terraform Operations

Before running any Terraform commands:

```bash
# Navigate to terraform directory
cd terraform

# Option 1: Bash (Git Bash, WSL, Linux)
source load_env.sh

# Option 2: PowerShell (Windows)
. .\load_env.ps1

# Option 3: Command Prompt (Windows)
load_env.bat

# Then run terraform commands
make deploy-compute
```

## Airflow Operations

The Airflow setup automatically loads environment variables:

```bash
cd airflow
# Ensure .env file is configured
./start_airflow.sh
```

## Verifying Configuration

Use the built-in checks:

```bash
# Check Terraform environment
cd terraform
make check-env

# Check Airflow environment  
cd airflow
source .env
echo "Redshift endpoint: $REDSHIFT_ENDPOINT"
```

## Troubleshooting

### "TF_VAR_redshift_admin_password not set"
- Ensure you've run one of the environment loading scripts:
  - `source load_env.sh` (Bash)
  - `. .\load_env.ps1` (PowerShell)  
  - `load_env.bat` (Command Prompt)
- Check that .env file exists and contains the variable
- Verify the variable name is exactly `TF_VAR_redshift_admin_password`

### "REDSHIFT_ADMIN_PASSWORD must be set"
- Check your .env file in the airflow directory
- Ensure no extra spaces around the equals sign
- **If password contains special characters (`&`, `$`, `!`, etc.), wrap it in quotes**: `REDSHIFT_ADMIN_PASSWORD="MyPassword&123"`
- Verify the password doesn't contain characters that need escaping

### Docker Compose environment issues
- Restart Docker Compose after changing .env files
- Check that .env file is in the same directory as docker-compose.yml
- Use `docker-compose config` to verify environment variable substitution

## Production Considerations

For production deployments:
- Use AWS Secrets Manager or similar for credential storage
- Implement credential rotation
- Use IAM roles instead of hardcoded credentials where possible
- Enable CloudTrail for audit logging
- Use least-privilege access principles
