# Networking Environment Outputs
# These outputs provide networking information for other environments

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "redshift_security_group_id" {
  description = "ID of the Redshift security group"
  value       = module.networking.redshift_security_group_id
}

output "general_security_group_id" {
  description = "ID of the general purpose security group"
  value       = module.networking.general_security_group_id
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = module.networking.s3_vpc_endpoint_id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.networking.availability_zones
}

# Configuration for use in compute environment
output "networking_configuration" {
  description = "Networking configuration for other environments"
  value = {
    vpc_id                       = module.networking.vpc_id
    private_subnet_ids          = module.networking.private_subnet_ids
    redshift_security_group_id  = module.networking.redshift_security_group_id
    aws_region                  = var.aws_region
  }
}
