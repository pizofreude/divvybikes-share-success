-- Database Initialization Script for Divvy Bikes Data Engineering Project
-- This script sets up the initial database structure for the data pipeline

-- Create schemas for the medallion architecture
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Create schema for staging data
CREATE SCHEMA IF NOT EXISTS staging;

-- Set search path to include all schemas
SET search_path TO public, bronze, silver, gold, staging;

-- Create external schema for S3 data
CREATE EXTERNAL SCHEMA IF NOT EXISTS external_bronze
FROM DATA CATALOG 
DATABASE 'divvy_bronze'
IAM_ROLE '${iam_role_arn}'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

CREATE EXTERNAL SCHEMA IF NOT EXISTS external_silver
FROM DATA CATALOG 
DATABASE 'divvy_silver'
IAM_ROLE '${iam_role_arn}'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

-- Create tables for bronze layer (raw data)
CREATE TABLE IF NOT EXISTS bronze.trips_raw (
    ride_id VARCHAR(50),
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name VARCHAR(100),
    start_station_id VARCHAR(50),
    end_station_name VARCHAR(100),
    end_station_id VARCHAR(50),
    start_lat DECIMAL(10,8),
    start_lng DECIMAL(11,8),
    end_lat DECIMAL(10,8),
    end_lng DECIMAL(11,8),
    member_casual VARCHAR(10),
    load_date TIMESTAMP DEFAULT GETDATE()
);

-- Create tables for silver layer (cleaned data)
CREATE TABLE IF NOT EXISTS silver.trips_cleaned (
    ride_id VARCHAR(50) PRIMARY KEY,
    rideable_type VARCHAR(20) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP NOT NULL,
    ride_length_minutes INTEGER,
    start_station_name VARCHAR(100),
    start_station_id VARCHAR(50),
    end_station_name VARCHAR(100),
    end_station_id VARCHAR(50),
    start_lat DECIMAL(10,8),
    start_lng DECIMAL(11,8),
    end_lat DECIMAL(10,8),
    end_lng DECIMAL(11,8),
    member_casual VARCHAR(10) NOT NULL,
    day_of_week INTEGER,
    hour_of_day INTEGER,
    month INTEGER,
    season VARCHAR(10),
    is_weekend BOOLEAN,
    is_round_trip BOOLEAN,
    trip_distance_km DECIMAL(8,3),
    load_date TIMESTAMP DEFAULT GETDATE(),
    updated_date TIMESTAMP DEFAULT GETDATE()
);

-- Create dimension tables for gold layer
CREATE TABLE IF NOT EXISTS gold.dim_stations (
    station_id VARCHAR(50) PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT GETDATE(),
    updated_date TIMESTAMP DEFAULT GETDATE()
);

CREATE TABLE IF NOT EXISTS gold.dim_time (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    season VARCHAR(10) NOT NULL
);

-- Create fact table for gold layer
CREATE TABLE IF NOT EXISTS gold.fct_trips (
    trip_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    ride_id VARCHAR(50) NOT NULL,
    start_date_key INTEGER,
    end_date_key INTEGER,
    start_station_id VARCHAR(50),
    end_station_id VARCHAR(50),
    rideable_type VARCHAR(20) NOT NULL,
    member_casual VARCHAR(10) NOT NULL,
    ride_length_minutes INTEGER,
    trip_distance_km DECIMAL(8,3),
    base_revenue DECIMAL(10,2),
    overage_revenue DECIMAL(10,2),
    total_revenue DECIMAL(10,2),
    is_round_trip BOOLEAN,
    hour_of_day INTEGER,
    day_of_week INTEGER,
    month INTEGER,
    season VARCHAR(10),
    is_weekend BOOLEAN,
    created_date TIMESTAMP DEFAULT GETDATE(),
    FOREIGN KEY (start_station_id) REFERENCES gold.dim_stations(station_id),
    FOREIGN KEY (end_station_id) REFERENCES gold.dim_stations(station_id),
    FOREIGN KEY (start_date_key) REFERENCES gold.dim_time(date_key),
    FOREIGN KEY (end_date_key) REFERENCES gold.dim_time(date_key)
);

-- Create revenue analysis views
CREATE OR REPLACE VIEW gold.vw_revenue_summary AS
SELECT 
    member_casual,
    rideable_type,
    DATE_TRUNC('month', created_date) as month,
    COUNT(*) as trip_count,
    SUM(base_revenue) as total_base_revenue,
    SUM(overage_revenue) as total_overage_revenue,
    SUM(total_revenue) as total_revenue,
    AVG(ride_length_minutes) as avg_ride_length_minutes,
    AVG(trip_distance_km) as avg_trip_distance_km
FROM gold.fct_trips
GROUP BY member_casual, rideable_type, DATE_TRUNC('month', created_date);

-- Create station performance view
CREATE OR REPLACE VIEW gold.vw_station_performance AS
SELECT 
    s.station_id,
    s.station_name,
    COUNT(*) as total_trips,
    COUNT(CASE WHEN f.member_casual = 'member' THEN 1 END) as member_trips,
    COUNT(CASE WHEN f.member_casual = 'casual' THEN 1 END) as casual_trips,
    SUM(f.total_revenue) as total_revenue,
    AVG(f.ride_length_minutes) as avg_ride_length
FROM gold.dim_stations s
LEFT JOIN gold.fct_trips f ON s.station_id = f.start_station_id
GROUP BY s.station_id, s.station_name;

-- Grant permissions for data pipeline access
GRANT ALL PRIVILEGES ON SCHEMA bronze TO "${username}";
GRANT ALL PRIVILEGES ON SCHEMA silver TO "${username}";
GRANT ALL PRIVILEGES ON SCHEMA gold TO "${username}";
GRANT ALL PRIVILEGES ON SCHEMA staging TO "${username}";

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA bronze TO "${username}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA silver TO "${username}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA gold TO "${username}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staging TO "${username}";

-- Success message
SELECT 'Database initialization completed successfully!' as status;
