-- Add All Partitions for External Tables - COMPREHENSIVE SETUP
-- Run this after the external schema has been successfully created
-- This script:
-- 1. Drops any existing tables with incorrect formats
-- 2. Creates tables with correct file formats (CSV for trips/weather, JSON for GBFS)
-- 3. Adds all partitions (72 total: 24 trips + 48 weather + 3 GBFS)

-- ========================================================================
-- STEP 1: Drop existing external tables (if they exist with wrong formats)
-- ========================================================================
DROP TABLE IF EXISTS divvy_bronze.divvy_trips;
DROP TABLE IF EXISTS divvy_bronze.weather_data;
DROP TABLE IF EXISTS divvy_bronze.gbfs_stations;

-- ========================================================================
-- STEP 2: Create external tables with CORRECT file formats
-- ========================================================================

-- Create divvy_trips table with CSV format
CREATE EXTERNAL TABLE divvy_bronze.divvy_trips (
    ride_id VARCHAR(50),
    rideable_type VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name VARCHAR(200),
    start_station_id VARCHAR(50),
    end_station_name VARCHAR(200),
    end_station_id VARCHAR(50),
    start_lat DOUBLE PRECISION,
    start_lng DOUBLE PRECISION,
    end_lat DOUBLE PRECISION,
    end_lng DOUBLE PRECISION,
    member_casual VARCHAR(50)
)
PARTITIONED BY (year VARCHAR(4), month VARCHAR(2))
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/'
TABLE PROPERTIES ('numRows'='1000000', 'skip.header.line.count'='1');

-- Create weather_data table with CSV format
CREATE EXTERNAL TABLE divvy_bronze.weather_data (
    time DATE,
    temperature_2m_max DOUBLE PRECISION,
    temperature_2m_min DOUBLE PRECISION,
    temperature_2m_mean DOUBLE PRECISION,
    apparent_temperature_max DOUBLE PRECISION,
    apparent_temperature_min DOUBLE PRECISION,
    apparent_temperature_mean DOUBLE PRECISION,
    precipitation_sum DOUBLE PRECISION,
    rain_sum DOUBLE PRECISION,
    snowfall_sum DOUBLE PRECISION,
    wind_speed_10m_max DOUBLE PRECISION,
    wind_gusts_10m_max DOUBLE PRECISION,
    wind_direction_10m_dominant INTEGER,
    cloud_cover_mean INTEGER
)
PARTITIONED BY (location VARCHAR(20), year VARCHAR(4), month VARCHAR(2))
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/'
TABLE PROPERTIES ('numRows'='1000', 'skip.header.line.count'='1');

-- Create gbfs_stations table with JSON format
CREATE EXTERNAL TABLE divvy_bronze.gbfs_stations (
    station_id VARCHAR(50),
    name VARCHAR(200),
    short_name VARCHAR(100),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    capacity INTEGER,
    legacy_id VARCHAR(50)
)
PARTITIONED BY (endpoint VARCHAR(50), year VARCHAR(4), month VARCHAR(2), day VARCHAR(2))
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
STORED AS TEXTFILE
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/'
TABLE PROPERTIES ('numRows'='1000');

-- ========================================================================
-- STEP 3: Add ALL partitions
-- ========================================================================

-- Add ALL partitions for divvy trips (2023: 12 months)
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=01/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=02/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=03/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=04/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=05/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=06/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=07/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=08/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=09/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=10/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=11/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2023', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2023/month=12/';

-- Add ALL partitions for divvy trips (2024: 12 months)
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=01/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=02/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=03/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=04/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=05/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=06/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=07/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=08/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=09/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=10/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=11/';
ALTER TABLE divvy_bronze.divvy_trips ADD PARTITION (year='2024', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/year=2024/month=12/';

-- Add ALL partitions for weather data - CHICAGO (24 months)
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=01/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=02/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=03/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=04/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=05/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=06/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=07/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=08/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=09/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=10/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=11/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2023', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2023/month=12/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=01/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=02/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=03/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=04/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=05/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=06/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=07/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=08/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=09/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=10/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=11/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='chicago', year='2024', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=chicago/year=2024/month=12/';

-- Add ALL partitions for weather data - EVANSTON (24 months)
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=01/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=02/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=03/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=04/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=05/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=06/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=07/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=08/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=09/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=10/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=11/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2023', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2023/month=12/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='01') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=01/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='02') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=02/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='03') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=03/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='04') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=04/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='05') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=05/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='06') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=06/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='07') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=07/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='08') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=08/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='09') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=09/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='10') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=10/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='11') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=11/';
ALTER TABLE divvy_bronze.weather_data ADD PARTITION (location='evanston', year='2024', month='12') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/location=evanston/year=2024/month=12/';

-- Add GBFS partitions (2025 data)
ALTER TABLE divvy_bronze.gbfs_stations ADD PARTITION (endpoint='station_information', year='2025', month='07', day='26') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/endpoint=station_information/year=2025/month=07/day=26/';
ALTER TABLE divvy_bronze.gbfs_stations ADD PARTITION (endpoint='station_status', year='2025', month='07', day='26') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/endpoint=station_status/year=2025/month=07/day=26/';
ALTER TABLE divvy_bronze.gbfs_stations ADD PARTITION (endpoint='system_information', year='2025', month='07', day='26') LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/endpoint=system_information/year=2025/month=07/day=26/';

-- ========================================================================
-- VERIFICATION QUERIES - Test all tables with correct file formats
-- ========================================================================
SELECT 'Setup complete! Testing data access...' as status;

-- Test data access with row counts from different years and locations
SELECT 'divvy_trips_2023' as table_name, COUNT(*) as row_count FROM divvy_bronze.divvy_trips WHERE year = '2023' AND month = '01';
SELECT 'divvy_trips_2024' as table_name, COUNT(*) as row_count FROM divvy_bronze.divvy_trips WHERE year = '2024' AND month = '01';
SELECT 'weather_chicago_2023' as table_name, COUNT(*) as row_count FROM divvy_bronze.weather_data WHERE location = 'chicago' AND year = '2023' AND month = '01';
SELECT 'weather_evanston_2024' as table_name, COUNT(*) as row_count FROM divvy_bronze.weather_data WHERE location = 'evanston' AND year = '2024' AND month = '01';
SELECT 'gbfs_stations_2025' as table_name, COUNT(*) as row_count FROM divvy_bronze.gbfs_stations WHERE endpoint = 'station_information' AND year = '2025';

-- Sample data preview
SELECT 'Sample 2023 trip data:' as info;
SELECT ride_id, rideable_type, started_at, member_casual FROM divvy_bronze.divvy_trips WHERE year = '2023' AND month = '01' LIMIT 3;

SELECT 'Sample 2024 trip data:' as info;
SELECT ride_id, rideable_type, started_at, member_casual FROM divvy_bronze.divvy_trips WHERE year = '2024' AND month = '01' LIMIT 3;

SELECT 'Sample Chicago weather data:' as info;
SELECT time, temperature_2m_mean, precipitation_sum FROM divvy_bronze.weather_data WHERE location = 'chicago' AND year = '2024' AND month = '01' LIMIT 3;

-- ========================================================================
-- SUCCESS INDICATORS:
-- ========================================================================
-- If successful, you should see:
-- ✅ divvy_trips: ~15,000-20,000 records per month
-- ✅ weather_data: ~31 records per location/month  
-- ✅ gbfs_stations: Variable count of station records
-- ✅ Sample data showing actual trip and weather information
-- 
-- Next steps:
-- 1. Verify all row counts are > 0
-- 2. Run dbt pipeline: dbt run
-- 3. Execute your analysis queries
-- ========================================================================
