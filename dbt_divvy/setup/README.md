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
