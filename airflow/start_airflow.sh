#!/bin/bash
# Airflow Startup and Configuration Script for Divvy Project

set -e

echo "🚀 Starting Airflow setup for Divvy Bikes Data Engineering Project"
echo "=================================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Docker is running"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the airflow directory."
    exit 1
fi

print_status "Found docker-compose.yml"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p ./dags ./logs ./plugins ./config ./scripts
chmod 755 ./dags ./logs ./plugins ./config ./scripts

print_status "Directories created"

# Set up environment variables
echo "🔧 Setting up environment variables..."
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please ensure .env file exists with required variables."
    exit 1
fi

# Source the environment file
source .env

print_status "Environment variables loaded"

# Initialize Airflow database
echo "🗄️ Initializing Airflow database..."
docker-compose up airflow-init

if [ $? -eq 0 ]; then
    print_status "Airflow database initialized"
else
    print_error "Failed to initialize Airflow database"
    exit 1
fi

# Start Airflow services
echo "🚁 Starting Airflow services..."
docker-compose up -d

if [ $? -eq 0 ]; then
    print_status "Airflow services started"
else
    print_error "Failed to start Airflow services"
    exit 1
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check if webserver is responding
for i in {1..10}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        print_status "Airflow webserver is ready"
        break
    else
        if [ $i -eq 10 ]; then
            print_error "Airflow webserver failed to start"
            exit 1
        fi
        echo "   Waiting for webserver... (attempt $i/10)"
        sleep 10
    fi
done

# Setup connections and variables
echo "🔗 Setting up Airflow connections and variables..."

# Wait a bit more for scheduler to be ready
sleep 10

# Setup connections using Airflow CLI
echo "   Setting up AWS connection..."
docker-compose exec airflow-webserver airflow connections add 'aws_default' \
    --conn-type 'aws' \
    --conn-extra '{"region_name": "ap-southeast-2"}' || print_warning "AWS connection may already exist"

echo "   Setting up Redshift connection..."
docker-compose exec airflow-webserver airflow connections add 'redshift_default' \
    --conn-type 'redshift' \
    --conn-host "${REDSHIFT_ENDPOINT}" \
    --conn-port "${REDSHIFT_PORT:-5439}" \
    --conn-schema "${REDSHIFT_DATABASE_NAME:-divvy}" \
    --conn-login "${REDSHIFT_ADMIN_USERNAME:-admin}" \
    --conn-password "${REDSHIFT_ADMIN_PASSWORD}" \
    --conn-extra "{\"workgroup\": \"${REDSHIFT_WORKGROUP}\", \"namespace\": \"${REDSHIFT_NAMESPACE}\"}" || print_warning "Redshift connection may already exist"

# Setup variables
echo "   Setting up Airflow variables..."
docker-compose exec airflow-webserver airflow variables set bronze_bucket "${BRONZE_BUCKET}"
docker-compose exec airflow-webserver airflow variables set silver_bucket "${SILVER_BUCKET}"
docker-compose exec airflow-webserver airflow variables set gold_bucket "${GOLD_BUCKET}"
docker-compose exec airflow-webserver airflow variables set divvy_source_bucket "divvy-tripdata"
docker-compose exec airflow-webserver airflow variables set data_years_to_process "2023,2024"

print_status "Connections and variables configured"

# Verify DAG is loaded
echo "📋 Checking DAG status..."
sleep 5

DAG_STATUS=$(docker-compose exec airflow-webserver airflow dags list | grep divvy_data_ingestion || echo "not found")
if [[ "$DAG_STATUS" == *"divvy_data_ingestion"* ]]; then
    print_status "Divvy data ingestion DAG loaded successfully"
else
    print_warning "DAG may still be loading. Check the Airflow UI in a few minutes."
fi

echo ""
echo "🎉 Airflow setup completed successfully!"
echo "============================================"
echo ""
echo "📍 Access Points:"
echo "   🌐 Airflow Web UI: http://localhost:8080"
echo "   👤 Username: admin"
echo "   🔑 Password: divvy2024"
echo ""
echo "🌸 Flower (Celery Monitor): http://localhost:5555 (if enabled)"
echo ""
echo "📋 Available DAGs:"
echo "   • divvy_data_ingestion - Main data ingestion pipeline"
echo ""
echo "🔧 Management Commands:"
echo "   • Stop Airflow: docker-compose down"
echo "   • View logs: docker-compose logs [service_name]"
echo "   • Restart: docker-compose restart"
echo ""
echo "📚 Next Steps:"
echo "   1. Open the Airflow UI at http://localhost:8080"
echo "   2. Log in with admin/divvy2024"
echo "   3. Navigate to DAGs and enable 'divvy_data_ingestion'"
echo "   4. Trigger the DAG manually to test data ingestion"
echo "   5. Monitor the progress in the Graph or Tree view"
echo ""
print_status "Setup complete! Happy data engineering! 🚀"
