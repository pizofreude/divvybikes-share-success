# Networking Module for Divvy Bikes Data Engineering Project
# This module creates the core networking infrastructure including VPC, subnets, and security groups

# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC - Main virtual private cloud for the project
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway - Provides internet access to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Public Subnets - For resources that need internet access
resource "aws_subnet" "public" {
  count = var.create_public_subnets ? length(var.public_subnet_cidrs) : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets - For internal resources (Redshift, etc.)
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = var.create_public_subnets ? length(aws_subnet.public) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoint for S3 - Allows private access to S3 without internet gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  })
}

# Associate S3 VPC endpoint with route tables
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = var.create_public_subnets ? 1 : 0

  route_table_id  = aws_route_table.public[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# Security Group for Redshift Serverless
resource "aws_security_group" "redshift" {
  name_prefix = "${var.project_name}-${var.environment}-redshift-"
  description = "Security group for Redshift Serverless"
  vpc_id      = aws_vpc.main.id

  # Redshift access from anywhere (for local Docker Airflow access)
  # Note: In production, this should be restricted to specific CIDR blocks
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Redshift access from anywhere"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for general purposes (can be used for other resources)
resource "aws_security_group" "general" {
  name_prefix = "${var.project_name}-${var.environment}-general-"
  description = "General purpose security group"
  vpc_id      = aws_vpc.main.id

  # HTTPS outbound
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # HTTP outbound
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-general-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
