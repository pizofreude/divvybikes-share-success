-- Create external schema and tables for Bronze layer data
-- This should be run once to set up the external tables in Redshift Spectrum

-- Create external schema
CREATE EXTERNAL SCHEMA IF NOT EXISTS divvy_bronze 
FROM DATA CATALOG 
DATABASE 'divvy_bronze_db' 
IAM_ROLE 'arn:aws:iam::864899839546:role/divvybikes-dev-redshift-role';

-- Create external table for divvy trips
CREATE EXTERNAL TABLE IF NOT EXISTS divvy_bronze.divvy_trips (
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
STORED AS PARQUET
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/divvy-trips/'
TABLE PROPERTIES ('numRows'='1000000');

-- Create external table for weather data
CREATE EXTERNAL TABLE IF NOT EXISTS divvy_bronze.weather_data (
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
PARTITIONED BY (year VARCHAR(4), month VARCHAR(2))
STORED AS PARQUET
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/weather-data/'
TABLE PROPERTIES ('numRows'='1000');

-- Create external table for GBFS stations
CREATE EXTERNAL TABLE IF NOT EXISTS divvy_bronze.gbfs_stations (
    station_id VARCHAR(50),
    name VARCHAR(200),
    short_name VARCHAR(100),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    capacity INTEGER,
    legacy_id VARCHAR(50)
)
STORED AS PARQUET
LOCATION 's3://divvybikes-dev-bronze-96wb3c9c/gbfs-data/'
TABLE PROPERTIES ('numRows'='1000');