# Networking Module

This module creates the networking infrastructure for the Divvy Bikes data engineering project, designed with cost optimization and security in mind.

## Architecture

The networking module creates:

- **VPC**: Virtual Private Cloud with DNS resolution enabled
- **Private Subnets**: For internal resources like Redshift Serverless (2 subnets across AZs)
- **Public Subnets**: Optional, disabled by default for cost optimization
- **Internet Gateway**: For internet access when needed
- **Route Tables**: Separate routing for public and private resources
- **VPC Endpoints**: S3 Gateway endpoint to avoid NAT gateway costs
- **Security Groups**: Pre-configured for Redshift and general use

## Cost Optimization Features

1. **Public Subnets Disabled by Default**: Reduces infrastructure complexity
2. **S3 VPC Endpoint**: Gateway endpoint (free) for S3 access from private subnets
3. **No NAT Gateway**: Eliminates ~$45/month cost per NAT gateway
4. **Minimal Security Groups**: Only necessary rules to reduce complexity

## Resources Created

| Resource | Purpose | Cost Impact |
|----------|---------|-------------|
| VPC | Network isolation | Free |
| Private Subnets (2) | Redshift placement | Free |
| Internet Gateway | Internet access | Free |
| Route Tables | Traffic routing | Free |
| S3 VPC Endpoint | Private S3 access | Free (Gateway) |
| Security Groups | Network security | Free |

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  project_name = "divvybikes"
  environment  = "dev"
  aws_region   = "ap-southeast-2"

  # VPC Configuration
  vpc_cidr              = "10.0.0.0/16"
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  
  # Cost optimization: disable public subnets
  create_public_subnets = false

  common_tags = {
    Project     = "DivvyBikes"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Outputs

The module provides outputs for:
- VPC ID and CIDR block
- Subnet IDs (public and private)
- Security group IDs
- VPC endpoint information
- Availability zones used

## Security Features

1. **Redshift Security Group**: Port 5439 access (configured for development)
2. **General Security Group**: HTTPS/HTTP outbound only
3. **Private Subnets**: No direct internet access
4. **VPC Endpoints**: Private communication with AWS services

## Development vs Production

For development:
- Redshift security group allows access from anywhere (0.0.0.0/0)
- Public subnets disabled by default

For production, consider:
- Restricting Redshift access to specific CIDR blocks
- Adding NAT Gateway if outbound internet access needed from private subnets
- Enabling VPC Flow Logs for monitoring

## Dependencies

None - this is a foundational module that other modules depend on.

## Notes

- This module is optimized for the Divvy Bikes project requirements
- Designed for ap-southeast-2 (Sydney) region
- Focuses on cost optimization while maintaining security
- Compatible with Redshift Serverless and S3 access patterns
- **Subnets**:
  - Private subnets for internal resources (Redshift Serverless)
  - Optional public subnets (disabled by default for cost optimization)

### Routing

- **Route Tables**: Separate routing for public and private subnets
- **Route Table Associations**: Links subnets to appropriate route tables

### Security

- **Redshift Security Group**: Allows access to Redshift on port 5439
- **General Security Group**: For other resources requiring HTTPS/HTTP access

### Cost Optimization Features

- **VPC Endpoint for S3**: Eliminates NAT gateway costs for S3 access
- **No NAT Gateway**: Reduces costs by avoiding NAT gateway provisioning
- **Minimal Public Infrastructure**: Public subnets disabled by default

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name = "divvybikes"
  environment  = "dev"
  aws_region   = "ap-southeast-2"

  # Customize CIDR blocks if needed
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  # Enable public subnets only if needed
  create_public_subnets = false

  common_tags = {
    Project     = "divvybikes"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "pizofreude"
  }
}
```

## Outputs

- `vpc_id`: VPC identifier for use in other modules
- `private_subnet_ids`: Private subnet IDs for Redshift deployment
- `redshift_security_group_id`: Security group for Redshift access
- `s3_vpc_endpoint_id`: VPC endpoint for cost-effective S3 access

## Security Considerations

- Redshift security group allows access from anywhere (0.0.0.0/0) for local Docker Airflow access
- In production environments, restrict Redshift access to specific CIDR blocks
- VPC endpoint provides secure S3 access without internet gateway traversal

## Cost Optimization

- No NAT gateway reduces monthly costs by ~$45 AUD
- VPC endpoint for S3 eliminates data transfer charges for S3 access
- Public subnets disabled by default to minimize infrastructure costs
