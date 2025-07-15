# Divvy Bikes Infrastructure Management Makefile
# This Makefile provides convenient commands for managing the entire infrastructure

# Variables
AWS_REGION := ap-southeast-2
PROJECT_NAME := divvybikes
ENVIRONMENT := dev

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Divvy Bikes Infrastructure Management$(NC)"
	@echo "======================================"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BLUE)Environment Setup:$(NC)"
	@echo "  Before running terraform commands, ensure you have:"
	@echo "  1. Copied .env.template to .env and configured it"
	@echo "  2. Set TF_VAR_redshift_admin_password: export TF_VAR_redshift_admin_password='your_password'"
	@echo "  3. Or run: source ../load_env.sh (from project root)"
	@echo ""
	@echo "$(BLUE)Typical workflow:$(NC)"
	@echo "  1. make deploy-networking"
	@echo "  2. make deploy-storage"
	@echo "  3. make deploy-compute"
	@echo "  4. make start-airflow"
	@echo ""

.PHONY: check-env
check-env: ## Check if required environment variables are set
	@echo "$(BLUE)Checking environment configuration...$(NC)"
	@if [ -z "$$TF_VAR_redshift_admin_password" ]; then \
		echo "$(RED)❌ TF_VAR_redshift_admin_password not set$(NC)"; \
		echo "$(YELLOW)Please set it with: export TF_VAR_redshift_admin_password='your_password'$(NC)"; \
		echo "$(YELLOW)Or source the load_env.sh script from project root$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)✅ Environment variables are properly configured$(NC)"; \
	fi

# Infrastructure Deployment Commands
.PHONY: deploy-networking
deploy-networking: ## Deploy networking infrastructure (VPC, subnets, security groups)
	@echo "$(GREEN)🌐 Deploying networking infrastructure...$(NC)"
	@chmod +x scripts/apply-networking.sh
	@./scripts/apply-networking.sh

.PHONY: deploy-storage
deploy-storage: ## Deploy storage infrastructure (S3 buckets, IAM roles)
	@echo "$(GREEN)🗄️  Deploying storage infrastructure...$(NC)"
	@chmod +x scripts/apply-storage.sh
	@./scripts/apply-storage.sh

.PHONY: deploy-compute
deploy-compute: check-env ## Deploy compute infrastructure (Redshift Serverless)
	@echo "$(GREEN)💻 Deploying compute infrastructure...$(NC)"
	@echo "📍 Changing to compute environment directory..."
	@cd environments/compute && \
	if [ ! -f "../networking/terraform.tfstate" ]; then \
		echo "❌ Networking infrastructure not found. Please run 'make deploy-networking' first"; \
		exit 1; \
	fi && \
	if [ ! -f "../storage/terraform.tfstate" ]; then \
		echo "❌ Storage infrastructure not found. Please run 'make deploy-storage' first"; \
		exit 1; \
	fi && \
	echo "✅ Prerequisites check passed" && \
	echo "🔧 Initializing Terraform..." && \
	terraform init && \
	echo "🔑 Setting password from environment..." && \
	if [ -z "$$TF_VAR_redshift_admin_password" ]; then \
		echo "❌ TF_VAR_redshift_admin_password environment variable not set"; \
		echo "Please set it or source your .env file"; \
		exit 1; \
	fi && \
	echo "✅ Validating configuration..." && \
	terraform validate && \
	echo "📋 Creating deployment plan..." && \
	terraform plan -var-file="terraform.tfvars" -out="compute.tfplan" && \
	echo "🚀 Applying deployment..." && \
	terraform apply -auto-approve compute.tfplan && \
	echo "📊 Deployment outputs:" && \
	terraform output

.PHONY: deploy-all
deploy-all: deploy-networking deploy-storage deploy-compute ## Deploy all infrastructure in correct order
	@echo "$(GREEN)✅ All infrastructure deployed successfully!$(NC)"
	@make status

# Airflow Management
.PHONY: setup-airflow
setup-airflow: ## Set up Airflow directory structure and Docker Compose
	@echo "$(GREEN)🔧 Setting up Airflow environment...$(NC)"
	@mkdir -p ../airflow/{dags,logs,plugins,config}
	@echo "$(GREEN)✅ Airflow directory structure created$(NC)"
	@echo "$(YELLOW)📝 Next: Copy docker-compose.yml from terraform plan and configure AWS credentials$(NC)"

.PHONY: start-airflow
start-airflow: ## Start Airflow using Docker Compose
	@echo "$(GREEN)🚀 Starting Airflow...$(NC)"
	@if [ ! -f ../airflow/docker-compose.yml ]; then \
		echo "$(RED)❌ docker-compose.yml not found in airflow directory$(NC)"; \
		echo "$(YELLOW)Run 'make setup-airflow' first$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔧 Running Airflow startup script...$(NC)"
	@cd ../airflow && chmod +x start_airflow.sh && ./start_airflow.sh
	@echo "$(GREEN)✅ Airflow started successfully$(NC)"
	@echo "$(BLUE)🌐 Airflow UI: http://localhost:8080$(NC)"
	@echo "$(BLUE)👤 Username: admin$(NC)"
	@echo "$(BLUE)🔑 Password: divvy2024$(NC)"

.PHONY: stop-airflow
stop-airflow: ## Stop Airflow containers
	@echo "$(YELLOW)🛑 Stopping Airflow...$(NC)"
	@cd ../airflow && docker-compose down
	@echo "$(GREEN)✅ Airflow stopped$(NC)"

.PHONY: restart-airflow
restart-airflow: stop-airflow start-airflow ## Restart Airflow containers

# Infrastructure Status and Information
.PHONY: status
status: ## Check status of all infrastructure components
	@echo "$(BLUE)📊 Infrastructure Status$(NC)"
	@echo "========================"
	@echo ""
	@echo "$(YELLOW)🌐 Networking:$(NC)"
	@if [ -f environments/networking/terraform.tfstate ]; then \
		echo "  ✅ Deployed"; \
		cd environments/networking && terraform output vpc_id 2>/dev/null | sed 's/^/  VPC: /' || echo "  ❌ Error reading state"; \
	else \
		echo "  ❌ Not deployed"; \
	fi
	@echo ""
	@echo "$(YELLOW)🗄️  Storage:$(NC)"
	@if [ -f environments/storage/terraform.tfstate ]; then \
		echo "  ✅ Deployed"; \
		cd environments/storage && terraform output bucket_names 2>/dev/null | head -3 | sed 's/^/  /' || echo "  ❌ Error reading state"; \
	else \
		echo "  ❌ Not deployed"; \
	fi
	@echo ""
	@echo "$(YELLOW)💻 Compute:$(NC)"
	@if [ -f environments/compute/terraform.tfstate ]; then \
		echo "  ✅ Deployed"; \
		cd environments/compute && terraform output redshift_endpoint 2>/dev/null | sed 's/^/  /' || echo "  ❌ Error reading state"; \
	else \
		echo "  ❌ Not deployed"; \
	fi
	@echo ""
	@echo "$(YELLOW)🐳 Docker (Airflow):$(NC)"
	@docker ps --filter "name=airflow" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "  ❌ Docker not available or no Airflow containers"

.PHONY: cost-estimate
cost-estimate: ## Show estimated monthly costs
	@echo "$(BLUE)💰 Cost Estimation for Divvy Bikes Infrastructure$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(GREEN)Resource                 | Est. Monthly Cost (AUD)$(NC)"
	@echo "-------------------------|------------------------"
	@echo "Docker (Local)           | $$0.00 (runs on local machine)"
	@echo "VPC & Networking         | $$0.00 (free tier)"
	@echo "S3 Storage (2GB)         | ~$$0.05"
	@echo "Redshift Serverless      | ~$$0.144/RPU-hr (when used)"
	@echo "Data Transfer            | < $$0.50"
	@echo "-------------------------|------------------------"
	@echo "$(YELLOW)Total (Minimal Usage)    | ~$$5-8/month$(NC)"
	@echo "$(YELLOW)Total (Active Dev)       | ~$$10-15/month$(NC)"
	@echo ""
	@echo "$(BLUE)💡 Cost Optimization Tips:$(NC)"
	@echo "• Redshift costs accrue per second when queried"
	@echo "• Use 'make destroy-compute' when not actively developing"
	@echo "• S3 Intelligent Tiering automatically optimizes storage costs"

# Resource Cleanup
.PHONY: destroy-compute
destroy-compute: ## Destroy compute infrastructure (preserves data)
	@echo "$(YELLOW)🗑️  Destroying compute infrastructure...$(NC)"
	@chmod +x scripts/destroy-compute.sh
	@./scripts/destroy-compute.sh

.PHONY: destroy-all
destroy-all: ## ⚠️  Destroy ALL infrastructure (including data!)
	@echo "$(RED)⚠️  WARNING: This will destroy ALL infrastructure including data!$(NC)"
	@read -p "Type 'DESTROY' to confirm complete destruction: " confirm; \
	if [ "$$confirm" = "DESTROY" ]; then \
		echo "$(RED)🗑️  Destroying all infrastructure...$(NC)"; \
		cd environments/compute && terraform destroy -auto-approve -var-file="terraform.tfvars" || true; \
		cd ../storage && terraform destroy -auto-approve -var-file="terraform.tfvars" || true; \
		cd ../networking && terraform destroy -auto-approve -var-file="terraform.tfvars" || true; \
		echo "$(GREEN)✅ All infrastructure destroyed$(NC)"; \
	else \
		echo "$(GREEN)❌ Destruction cancelled$(NC)"; \
	fi

# Development Helpers
.PHONY: init-all
init-all: ## Initialize all Terraform environments
	@echo "$(GREEN)📦 Initializing all Terraform environments...$(NC)"
	@cd environments/networking && terraform init
	@cd environments/storage && terraform init
	@cd environments/compute && terraform init
	@echo "$(GREEN)✅ All environments initialized$(NC)"

.PHONY: validate-all
validate-all: ## Validate all Terraform configurations
	@echo "$(GREEN)✅ Validating all Terraform configurations...$(NC)"
	@cd environments/networking && terraform validate && echo "  ✅ Networking valid"
	@cd environments/storage && terraform validate && echo "  ✅ Storage valid"
	@cd environments/compute && terraform validate && echo "  ✅ Compute valid"
	@echo "$(GREEN)✅ All configurations valid$(NC)"

.PHONY: plan-all
plan-all: ## Run terraform plan for all environments
	@echo "$(GREEN)📋 Planning all infrastructure...$(NC)"
	@cd environments/networking && terraform plan -var-file="terraform.tfvars"
	@cd environments/storage && terraform plan -var-file="terraform.tfvars"
	@cd environments/compute && terraform plan -var-file="terraform.tfvars"

# AWS CLI Helpers
.PHONY: aws-check
aws-check: ## Check AWS credentials and configuration
	@echo "$(BLUE)🔍 Checking AWS configuration...$(NC)"
	@aws sts get-caller-identity 2>/dev/null || echo "$(RED)❌ AWS credentials not configured$(NC)"
	@echo "$(BLUE)📍 Current region: $(NC)$$(aws configure get region || echo 'Not set')"

.PHONY: s3-list
s3-list: ## List all project S3 buckets
	@echo "$(BLUE)🪣 Project S3 Buckets:$(NC)"
	@aws s3 ls | grep $(PROJECT_NAME) || echo "$(YELLOW)No project buckets found$(NC)"

# Quick Start
.PHONY: quick-start
quick-start: aws-check deploy-all start-airflow status ## Complete quick start deployment
	@echo ""
	@echo "$(GREEN)🎉 Quick start complete!$(NC)"
	@echo "$(BLUE)🌐 Airflow UI: http://localhost:8080$(NC)"
	@echo "$(BLUE)👤 Credentials: admin/admin$(NC)"
