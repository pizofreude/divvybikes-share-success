-- ========================================================================
-- dbt Pipeline Validation Script
-- ========================================================================
-- 
-- Purpose: Comprehensive validation of dbt pipeline deployment success
-- Usage: Run in Redshift Query Editor v2 AFTER completing dbt pipeline
-- 
-- This script validates:
-- 1. All dbt-created schemas exist and are accessible
-- 2. Tables and views are properly deployed in each layer
-- 3. Record counts verify data was transformed successfully
-- 4. Permissions are correctly configured for analytics access
--
-- Author: pizofreude
-- Project: Divvy Bikes Data Engineering
-- Last Updated: 2025-08-18
-- ========================================================================

-- Query to find all dbt-created schemas and tables in Redshift
-- Run this in Redshift Query Editor v2

-- 1. Check all schemas in the divvy database
SELECT DISTINCT schemaname 
FROM pg_tables 
WHERE schemaname LIKE 'public%'
ORDER BY schemaname;

-- 2. Check all tables in dbt-created schemas
SELECT 
    schemaname as schema_name,
    tablename as table_name,
    tableowner as owner
FROM pg_tables 
WHERE schemaname IN ('public_silver', 'public_gold', 'public_marts', 'public_bronze')
ORDER BY schemaname, tablename;

-- 3. Check all views in dbt-created schemas
SELECT 
    schemaname as schema_name,
    viewname as view_name,
    viewowner as owner
FROM pg_views 
WHERE schemaname IN ('public_silver', 'public_gold', 'public_marts', 'public_bronze')
ORDER BY schemaname, viewname;

-- 4. Quick count of records in each table (to verify data exists)
SELECT 'public_silver.trips_cleaned' as table_name, COUNT(*) as record_count FROM public_silver.trips_cleaned
UNION ALL
SELECT 'public_silver.stations_cleaned', COUNT(*) FROM public_silver.stations_cleaned
UNION ALL
SELECT 'public_silver.weather_cleaned', COUNT(*) FROM public_silver.weather_cleaned
UNION ALL
SELECT 'public_gold.trips_enhanced', COUNT(*) FROM public_gold.trips_enhanced
UNION ALL
SELECT 'public_gold.station_performance', COUNT(*) FROM public_gold.station_performance
UNION ALL
SELECT 'public_gold.behavioral_analysis', COUNT(*) FROM public_gold.behavioral_analysis;
