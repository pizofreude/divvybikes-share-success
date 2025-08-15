# dbt Execution Commands for Divvy Bikes Project

## ✅ IMPORTANT: Phase 1 - External Tables Setup (One-Time Only)

**You MUST complete this phase before running any dbt commands!**

> **🎯 Final Working Solution (after extensive debugging):**
> The solution involves 3 clean steps using the files in `setup/` directory.

### Step 1: Create Glue Catalog Tables
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy/setup
chmod +x create_glue_tables.sh
./create_glue_tables.sh
```

**Expected Output:**
```
✅ Creating table: divvy_trips
✅ Creating table: weather_data  
✅ Creating table: gbfs_stations
✅ All 3 tables created successfully in divvybikes_bronze_db
```

### Step 2: Create External Schema in Redshift

1. **Connect to Redshift Serverless**:
   - Open AWS Console → Amazon Redshift → Query editor v2
   - Connect to: `divvybikes-dev.864899839546.ap-southeast-2.redshift-serverless.amazonaws.com`
   - Database: `divvy`

2. **Run External Schema Setup**:
   ```sql
   -- Copy and paste the ENTIRE contents of setup/debug_external_schema.sql
   -- This will drop and recreate the external schema to refresh table visibility
   ```

3. **Expected Results**:
   ```
   ✅ External schema created
   ✅ 3 tables visible: divvy_trips, gbfs_stations, weather_data
   ```

### Step 3: Add All Partitions

**In Redshift Query Editor:**
```sql
-- Copy and paste the ENTIRE contents of setup/add_all_partitions.sql
-- This adds all 72 partitions (24 trips + 48 weather) and tests data access
```

**Expected Results:**
```
✅ 72 partitions added successfully
✅ divvy_trips_2023: ~190,301 rows
✅ divvy_trips_2024: ~144,873 rows  
✅ weather_chicago_2023: ~31 rows
✅ weather_evanston_2024: ~31 rows
✅ Sample data visible from both years
```

### ✅ Verification Steps

After completing all 3 steps above, your external tables are ready! 

**Quick Verification in Redshift:**
```sql
-- Should show 3 tables
SELECT schemaname, tablename 
FROM svv_external_tables 
WHERE schemaname = 'divvy_bronze';
```

**Quick Verification in dbt:**
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy

# Test dbt connection
dbt debug
# Expected: All checks pass including connection to divvy database

# Test source access  
dbt source freshness
# Expected: Sources accessible with data
```

---

## Quick Start (After Phase 1 Complete)

```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy
./run_dbt_pipeline.sh
```

## Manual Step-by-Step Execution

### 1. Setup and Dependencies
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy

# Install dbt packages
dbt deps

# Test connection to Redshift
dbt debug

# Check source data freshness
dbt source freshness
```

### 2. Silver Layer (Data Cleaning)
```bash
# Run Silver layer models
dbt run --models trips_cleaned weather_cleaned stations_cleaned

# Test Silver layer data quality
dbt test --models trips_cleaned weather_cleaned stations_cleaned

# Or run individually
dbt run --models trips_cleaned
dbt run --models weather_cleaned
dbt run --models stations_cleaned
```

### 3. Gold Layer (Business Logic)
```bash
# Run Gold layer models (depends on Silver)
dbt run --models trips_enhanced station_performance behavioral_analysis

# Test Gold layer
dbt test --models trips_enhanced station_performance behavioral_analysis

# Or run individually
dbt run --models trips_enhanced
dbt run --models station_performance
dbt run --models behavioral_analysis
```

### 4. Business Marts
```bash
# Run business marts (depends on Gold)
dbt run --models conversion_opportunities

# Test marts
dbt test --models conversion_opportunities
```

### 5. Documentation and Final Tests
```bash
# Generate documentation
dbt docs generate

# Run all tests
dbt test

# Serve documentation
dbt docs serve --port 8080
```

## Selective Execution

### Run by Layer
```bash
# Silver layer only
dbt run --models tag:silver
dbt test --models tag:silver

# Gold layer only
dbt run --models tag:gold
dbt test --models tag:gold

# Marts layer only
dbt run --models tag:marts
```

### Run Specific Models
```bash
# Single model
dbt run --models trips_enhanced

# Model and downstream dependencies
dbt run --models trips_enhanced+

# Model and upstream dependencies
dbt run --models +trips_enhanced

# Model and all dependencies
dbt run --models +trips_enhanced+
```

### Run with Filters
```bash
# Modified models only
dbt run --models state:modified

# Full refresh (ignore incremental logic)
dbt run --full-refresh

# Exclude specific models
dbt run --exclude trips_enhanced
```

## Development and Debug Commands

### Compile and Debug
```bash
# Compile SQL without running
dbt compile --models trips_enhanced

# Show compiled SQL
dbt show --models trips_enhanced

# Debug with verbose logging
dbt run --models trips_enhanced --debug

# Parse project for syntax errors
dbt parse
```

### Testing Commands
```bash
# Run specific test
dbt test --models trips_cleaned

# Run custom tests only
dbt test --select test_type:singular

# Run generic tests only
dbt test --select test_type:generic

# Store test failures for analysis
dbt test --store-failures
```

## Performance and Monitoring

### Performance Analysis
```bash
# Run with performance logging
dbt run --models trips_enhanced --log-level debug

# Compile to see query execution plans
dbt compile --models trips_enhanced
# Then check target/compiled/ for SQL to analyze in Redshift
```

### Monitoring Commands
```bash
# Check model metadata
dbt ls --models trips_enhanced --resource-type model

# Check test coverage
dbt ls --resource-type test

# Show model dependencies
dbt deps --models trips_enhanced
```

## Troubleshooting Commands

### Connection Issues
```bash
# Debug connection
dbt debug

# Test with simple query
dbt run-operation dbt_utils.current_timestamp
```

### Data Issues
```bash
# Check source data
dbt source freshness

# Validate individual sources
SELECT COUNT(*) FROM {{ source('divvy_bronze', 'divvy_trips') }} LIMIT 5;
```

### Performance Issues
```bash
# Full refresh to rebuild incrementals
dbt run --full-refresh --models trips_enhanced

# Clean artifacts
dbt clean

# Check for orphaned files
dbt clean && dbt deps
```

## Production Deployment

### Airflow Integration
```bash
# The DAG file is already created at:
# /c/workspace/divvybikes-share-success/airflow/dags/dbt_transformation_dag.py

# Test DAG syntax
python /c/workspace/divvybikes-share-success/airflow/dags/dbt_transformation_dag.py
```

### Scheduled Runs
```bash
# Daily incremental refresh
dbt run --models trips_enhanced+

# Weekly full refresh
dbt run --full-refresh --models trips_enhanced+

# Monthly reprocess all
dbt run --full-refresh
```

## Environment Variables
```bash
# Set dbt profile (if needed)
export DBT_PROFILES_DIR=~/.dbt/

# Set target environment
dbt run --target prod

# Override variables
dbt run --vars '{"redshift_spectrum_role": "arn:aws:iam::864899839546:role/divvybikes-dev-redshift-role"}'
```

## Success Indicators
After successful execution, you should see:
- ✅ All Silver layer models created in `silver` schema
- ✅ All Gold layer models created in `gold` schema  
- ✅ All Marts created in `marts` schema
- ✅ All tests passing
- ✅ Documentation generated and served
- ✅ External tables accessible via dbt sources
