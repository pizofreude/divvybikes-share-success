# External Tables Setup - Working Solution

This directory contains the **final working solution** for setting up external tables after extensive debugging.

## 🎯 What This Solves

The external tables setup had several complex issues:
- ✅ **Timing Issue**: External schema was created before Glue tables existed
- ✅ **Glue Database**: Empty database needed to be populated with table definitions  
- ✅ **Partitioning**: All 72 partitions (24 trips + 48 weather) needed to be added
- ✅ **Authentication**: Proper IAM role permissions for Redshift Spectrum

## 📁 Files in This Directory

### 1. `create_glue_tables.sh`
**Purpose**: Creates the 3 Glue catalog table definitions
**When to use**: Run this FIRST via command line
**What it does**: 
- Creates `divvy_trips` table schema in Glue
- Creates `weather_data` table schema in Glue  
- Creates `gbfs_stations` table schema in Glue

```bash
chmod +x create_glue_tables.sh
./create_glue_tables.sh
```

### 2. `debug_external_schema.sql` 
**Purpose**: Creates external schema and refreshes table visibility
**When to use**: Run this SECOND in Redshift Query Editor
**What it does**:
- Drops any existing external schema (if exists)
- Creates fresh external schema connected to Glue database
- Verifies all 3 tables are visible

### 4. `test-aws-connection.sh`
**Purpose**: Diagnoses AWS connectivity and permission issues
**When to use**: Run this BEFORE setup if you encounter AWS access problems
**What it does**:
- Tests AWS credentials via `aws sts get-caller-identity`
- Verifies S3 bucket access permissions
- Shows current AWS configuration details
- Provides troubleshooting guidance

```bash
chmod +x test-aws-connection.sh
./test-aws-connection.sh
```

**Expected Output**:
```
✅ AWS credentials are valid!
✅ S3 access works!
✅ Can access Divvy Bikes S3 bucket!
```

### 3. `add_all_partitions.sql`
**Purpose**: Adds all 72 partitions and tests data access  
**When to use**: Run this THIRD in Redshift Query Editor
**What it does**:
- Adds 24 divvy_trips partitions (2023-2024, 12 months each)
- Adds 48 weather_data partitions (Chicago + Evanston, 2023-2024, 12 months each)  
- Adds GBFS station partitions
- Tests data access with row counts
- Shows sample data from each table

## 🚀 Usage Instructions

**Step 1**: Create Glue tables
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy/setup
./create_glue_tables.sh
```

**Step 2**: Create external schema in Redshift
- Open Redshift Query Editor v2
- Copy/paste contents of `debug_external_schema.sql`
- Execute

**Step 3**: Add partitions in Redshift  
- Copy/paste contents of `add_all_partitions.sql`
- Execute (takes ~2-3 minutes)

**Expected Final Results**:
```
✅ divvy_trips_2023: ~190,301 rows
✅ divvy_trips_2024: ~144,873 rows  
✅ weather_chicago_2023: ~31 rows per month
✅ weather_evanston_2024: ~31 rows per month
✅ Sample data visible from all tables
```

## ✅ Success Indicators

After running all 3 files, you should have:
- ✅ 3 Glue tables in `divvybikes_bronze_db`
- ✅ External schema `divvy_bronze` in Redshift
- ✅ 72 partitions with actual data access
- ✅ Sample queries returning real trip and weather data

## 🧹 What Was Cleaned Up

**Removed Files** (failed attempts):
- `setup_external_tables_federated.sql` - Authentication issues  
- `setup_external_schema_final.sql` - Timing problems
- `setup_external_tables_complete.sql` - Multiple versions
- `grant_permissions.sql` - Debug attempts
- Various other debugging SQL files

**Working Architecture**:
```
Terraform → Glue Database → AWS CLI → Glue Tables → External Schema → Partitions → Data Access
```

This is the **clean, final solution** that actually works.

---

## 📊 dbt Pipeline Validation & Analytics Setup

### Additional Utility Files for dbt Pipeline Management

### 5. `check_dbt_tables.sql`

**Purpose**: Validates dbt pipeline deployment success after transformation  
**When to use**: Run this AFTER completing dbt pipeline execution  
**What it does**:

- Verifies all dbt-created schemas exist (`public_silver`, `public_gold`, `public_marts`)
- Lists all deployed tables and views with ownership information
- Validates record counts across all transformation layers
- Provides comprehensive pipeline deployment verification

**Usage in Redshift Query Editor v2**:

```sql
-- Run each section to verify different aspects:
-- 1. Schema verification
-- 2. Table/view inventory  
-- 3. Record count validation
-- 4. Data access confirmation
```

### 6. `grant_permissions.sql`

**Purpose**: Enables full schema access for analytics work in Redshift Query Editor v2  
**When to use**: Run this when switching from Federated to Database user connection  
**What it does**:

- Grants USAGE permissions on all dbt-created schemas
- Enables SELECT access to all tables and views  
- Resolves "permission denied" errors on silver/gold layers
- Ensures full UI visibility in Redshift Query Editor v2

**Critical for Analytics Work**:

```sql
-- Required when switching connection types:
-- Federated User → Database User Name & Password
-- Enables complete schema browser functionality
-- Resolves permission denied errors
```

## 🔄 Complete Workflow: External Tables → dbt Pipeline → Analytics

### Phase 1: External Tables Setup (Bronze Layer)

```bash
# Connection Type: Federated User (recommended)
# Setup bronze layer access to S3 data

1. ./create_glue_tables.sh
2. Run debug_external_schema.sql
3. Run add_all_partitions.sql
```

### Phase 2: dbt Pipeline Execution

```bash
# Connection Type: Either Federated or Database User
# Transform bronze → silver → gold → marts

1. dbt deps
2. dbt debug  
3. dbt run
4. dbt test
```

### Phase 3: Analytics & Validation

```bash
# Connection Type: Database User Name & Password (required)
# Validate deployment and enable analytics access

1. Switch to Database user connection in Redshift Query Editor v2
2. Run grant_permissions.sql (resolve permission issues)
3. Run check_dbt_tables.sql (verify pipeline success) 
4. Begin business analytics work
```

## 🔧 Connection Type Best Practices

| Phase | Connection Type | Purpose | Files to Use |
|-------|----------------|---------|--------------|
| **Bronze Setup** | Federated User | S3 external table access | `create_glue_tables.sh`, `debug_external_schema.sql`, `add_all_partitions.sql` |
| **dbt Development** | Either | Pipeline development | Standard dbt commands |
| **Analytics** | Database User + Password | Full schema visibility | `grant_permissions.sql`, `check_dbt_tables.sql` |

## 🚨 Troubleshooting Guide

**Problem**: dbt pipeline shows success but tables not visible in Redshift UI  
**Solution**:

1. Switch to Database user connection
2. Run `grant_permissions.sql`
3. Run `check_dbt_tables.sql` to verify
4. Refresh Redshift Query Editor v2

**Problem**: Permission denied errors on silver/gold schemas  
**Solution**: Run `grant_permissions.sql` with Database user connection

**Problem**: Cannot verify if dbt pipeline worked correctly  
**Solution**: Run `check_dbt_tables.sql` for comprehensive validation
