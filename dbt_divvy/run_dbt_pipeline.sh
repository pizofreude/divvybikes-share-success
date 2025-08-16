#!/bin/bash

# dbt Execution Script for Divvy Bikes Project
# This script runs the complete dbt workflow in the correct order

set -e  # Exit on any error

echo "🚀 Starting dbt transformation pipeline for Divvy Bikes project..."

# Change to dbt project directory
cd "$(dirname "$0")"

# Check if external tables are set up
echo "🔍 Checking external tables setup..."
if ! dbt debug &>/dev/null; then
    echo "❌ dbt connection failed!"
    echo "📋 Please run the setup process from setup/ directory first"
    echo "   See SETUP_CHECKLIST.md for complete instructions"
    exit 1
fi

# Test source accessibility
echo "🧪 Testing source data accessibility..."
if ! dbt source freshness &>/dev/null; then
    echo "⚠️ External tables may not be set up properly"
    echo "📋 Please ensure you've completed the setup process in setup/ directory"
    echo "   See SETUP_CHECKLIST.md for complete instructions"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Complete the setup process first"
        echo "   See SETUP_CHECKLIST.md for instructions"
        exit 1
    fi
fi

# Install dependencies
echo "📦 Installing dbt packages..."
dbt deps

# Create external tables (run once)
echo "🗄️ Setting up external tables in Redshift Spectrum..."
echo "Note: Make sure your Bronze layer external tables are created in Redshift"

# Debug connection
echo "🔍 Testing dbt connection..."
dbt debug

# Run source freshness checks
echo "🕐 Checking source data freshness..."
dbt source freshness || echo "⚠️ Source freshness check failed, continuing..."

# Clean up previous runs
echo "🧹 Cleaning previous runs..."
dbt clean

# Run Silver layer models
echo "🥈 Running Silver layer transformations..."
dbt run --models tag:silver

# Test Silver layer
echo "✅ Testing Silver layer data quality..."
dbt test --models tag:silver

# Run Gold layer models
echo "🥇 Running Gold layer transformations..."
dbt run --models tag:gold

# Test Gold layer
echo "✅ Testing Gold layer data quality..."
dbt test --models tag:gold

# Run Marts layer
echo "📊 Running business marts..."
dbt run --models tag:marts

# Generate documentation
echo "📚 Generating documentation..."
dbt docs generate

# Run all tests
echo "🔬 Running comprehensive test suite..."
dbt test

echo "✅ dbt pipeline completed successfully!"
echo "📈 Your Divvy Bikes data is now transformed and ready for analysis!"
echo "📖 View documentation: dbt docs serve"

# Optional: Start documentation server
read -p "🌐 Start documentation server? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting documentation server on http://localhost:8080"
    dbt docs serve --port 8080
fi
