# 🚀 dbt Setup Checklist for Divvy Bikes Project

Follow this checklist to ensure proper setup before running dbt transformations.

## ✅ Phase 1: External Tables Setup (REQUIRED FIRST!)

### Step 1.1: Create Glue Catalog Tables
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy/setup
chmod +x create_glue_tables.sh
./create_glue_tables.sh
```
- [x] 3 Glue tables created successfully ✅

### Step 1.2: Create External Schema in Redshift
- [x] Open AWS Console → Amazon Redshift → Query editor v2
- [x] Connect to: `divvybikes-dev.864899839546.ap-southeast-2.redshift-serverless.amazonaws.com`
- [x] Database: `divvy`
- [x] Open file: `setup/debug_external_schema.sql`
- [x] Copy and paste all SQL content
- [x] Execute - should show 3 tables: divvy_trips, weather_data, gbfs_stations

### Step 1.3: Add All Partitions
- [x] In Redshift Query Editor, open file: `setup/add_all_partitions.sql`
- [x] Copy and paste all SQL content (adds 72 partitions)
- [x] Execute - should return data counts:
  - divvy_trips_2023: ~190,301 rows ✅
  - divvy_trips_2024: ~144,873 rows ✅  
  - weather data: ~31 rows per location/month ✅

### Step 1.4: Verify Data Access
The partition script includes test queries that should show:
- [x] Sample 2023 trip data ✅
- [x] Sample 2024 trip data ✅
- [x] Weather data for Chicago and Evanston ✅

---

## ✅ Phase 2: dbt Configuration

### Step 2.1: Verify dbt Connection
```bash
cd /c/workspace/divvybikes-share-success/dbt_divvy
dbt debug
```
- [ ] Connection successful ✅

### Step 2.2: Install Dependencies
```bash
dbt deps
```
- [ ] Packages installed ✅

### Step 2.3: Test Source Access
```bash
dbt source freshness
```
- [ ] Sources accessible ✅

---

## ✅ Phase 3: Run dbt Pipeline

### Option A: Automated Pipeline (Recommended)
```bash
./run_dbt_pipeline.sh
```

### Option B: Manual Step-by-Step
```bash
# Silver layer
dbt run --models trips_cleaned weather_cleaned stations_cleaned
dbt test --models trips_cleaned weather_cleaned stations_cleaned

# Gold layer  
dbt run --models trips_enhanced station_performance behavioral_analysis
dbt test --models trips_enhanced station_performance behavioral_analysis

# Marts layer
dbt run --models conversion_opportunities
dbt test --models conversion_opportunities

# Documentation
dbt docs generate
dbt docs serve --port 8080
```

---

## ✅ Success Indicators

After successful completion, you should have:

- [ ] **Silver schema**: `trips_cleaned`, `weather_cleaned`, `stations_cleaned` tables
- [ ] **Gold schema**: `trips_enhanced`, `station_performance`, `behavioral_analysis` tables  
- [ ] **Marts schema**: `conversion_opportunities` view
- [ ] **All tests passing**: No data quality issues
- [ ] **Documentation available**: Accessible at http://localhost:8080

---

## 🚨 Troubleshooting Common Issues

### Issue: "External table not found"
**Solution**: Complete Phase 1 - External Tables Setup

### Issue: "Permission denied on S3"  
**Solution**: Verify IAM role `divvybikes-dev-redshift-role` has S3 access

### Issue: "dbt debug fails"
**Solution**: Check `~/.dbt/profiles.yml` configuration

### Issue: "No data in external tables"
**Solution**: Verify your Bronze layer S3 buckets contain parquet files

### Issue: "Tests failing"
**Solution**: Check data quality in Bronze layer, may need data cleaning

---

## 📞 Quick Commands Reference

```bash
# PHASE 1: External Tables Setup (one-time)
cd /c/workspace/divvybikes-share-success/dbt_divvy/setup
./create_glue_tables.sh
# Then run debug_external_schema.sql in Redshift Query Editor
# Then run add_all_partitions.sql in Redshift Query Editor

# PHASE 2: dbt Pipeline
cd /c/workspace/divvybikes-share-success/dbt_divvy
./run_dbt_pipeline.sh  

# Debug connection
dbt debug

# Test specific layer
dbt test --models tag:silver

# Generate docs
dbt docs generate && dbt docs serve --port 8080
```

---

**🎯 Goal**: Transform Bronze → Silver → Gold → Marts for Divvy Bikes conversion analysis
**⏱️ Estimated time**: 15-30 minutes for full setup and initial run
**📚 Documentation**: See `EXECUTION_GUIDE.md` for detailed commands
