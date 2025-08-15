-- Debug: Check External Schema Creation
-- Run this first to diagnose the issue

-- Step 1: Check if external schema exists (fixed column names)
SELECT schemaname, databasename, esoptions
FROM svv_external_schemas;

-- Step 2: Check current user and permissions
SELECT current_user, session_user;

-- Step 3: Drop and recreate external schema to refresh table visibility
DROP SCHEMA IF EXISTS divvy_bronze CASCADE;

CREATE EXTERNAL SCHEMA divvy_bronze 
FROM DATA CATALOG 
DATABASE 'divvybikes_bronze_db' 
IAM_ROLE 'arn:aws:iam::864899839546:role/divvybikes-dev-redshift-role';

-- Step 4: Verify external schema exists after recreation
SELECT schemaname, databasename, esoptions
FROM svv_external_schemas 
WHERE schemaname = 'divvy_bronze';

-- Step 5: Check if tables are NOW visible after schema recreation
SELECT schemaname, tablename 
FROM svv_external_tables 
WHERE schemaname = 'divvy_bronze';
