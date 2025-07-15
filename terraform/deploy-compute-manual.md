# Manual Compute Deployment Guide

Since the automated script is having issues, here's how to manually deploy the compute infrastructure:

## Prerequisites Check

1. Verify networking state exists:
   ```bash
   ls -la terraform/environments/networking/terraform.tfstate
   ```

2. Verify storage state exists:
   ```bash
   ls -la terraform/environments/storage/terraform.tfstate
   ```

## Manual Deployment Steps

1. Navigate to compute environment:
   ```bash
   cd terraform/environments/compute
   ```

2. Initialize Terraform (if not already done):
   ```bash
   terraform init
   ```

3. Set the Redshift admin password:
   ```bash
   export TF_VAR_redshift_admin_password="your_secure_password_here"
   ```

4. Validate the configuration:
   ```bash
   terraform validate
   ```

5. Create deployment plan:
   ```bash
   terraform plan -var-file="terraform.tfvars" -out="compute.tfplan"
   ```

6. Review the plan:
   ```bash
   terraform show compute.tfplan
   ```

7. Apply the deployment:
   ```bash
   terraform apply compute.tfplan
   ```

8. View outputs:
   ```bash
   terraform output
   ```

## Expected Outputs

The deployment should create:
- Redshift Serverless workgroup and namespace
- Security groups and IAM roles
- Database and user configurations
- Cost monitoring and limits

## Troubleshooting

If you encounter errors:
1. Check AWS credentials are properly configured
2. Verify the prerequisite states are available
3. Ensure the password meets complexity requirements
4. Check for any resource conflicts
