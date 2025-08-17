-- ========================================================================
-- Redshift Permission Management Script
-- ========================================================================
-- 
-- Purpose: Grant full schema access for analytics work in Redshift Query Editor v2
-- Usage: Run when switching from Federated to Database user connection
-- 
-- This script enables:
-- 1. USAGE permissions on all dbt-created schemas
-- 2. SELECT access to all tables and views across layers
-- 3. Full UI visibility in Redshift Query Editor v2 schema browser
-- 4. Resolution of "permission denied" errors on silver/gold layers
--
-- Connection Requirement: Database User Name and Password
-- 
-- Author: pizofreude
-- Project: Divvy Bikes Data Engineering
-- Last Updated: 2025-08-18
-- ========================================================================

-- Grant permissions to access dbt-created schemas and tables
-- Run this in Redshift Query Editor v2

-- Grant usage on schemas
GRANT USAGE ON SCHEMA public_silver TO PUBLIC;
GRANT USAGE ON SCHEMA public_gold TO PUBLIC;
GRANT USAGE ON SCHEMA public_marts TO PUBLIC;

-- Grant select permissions on all tables in each schema
GRANT SELECT ON ALL TABLES IN SCHEMA public_silver TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA public_gold TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA public_marts TO PUBLIC;

-- Grant select permissions on all views in each schema
GRANT SELECT ON ALL TABLES IN SCHEMA public_marts TO PUBLIC;

-- Verify permissions by counting records
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
SELECT 'public_gold.behavioral_analysis', COUNT(*) FROM public_gold.behavioral_analysis
UNION ALL
SELECT 'public_marts.conversion_opportunities', COUNT(*) FROM public_marts.conversion_opportunities
ORDER BY table_name;
