-- Add All Partitions for External Tables
-- Run this after the external schema has been successfully created
-- This adds all 72 partitions (24 trips + 48 weather)

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

-- Verification queries
SELECT 'Setup complete! Testing data access...' as status;

-- Test data access with row counts from different years and locations
SELECT 'divvy_trips_2023' as table_name, COUNT(*) as row_count FROM divvy_bronze.divvy_trips WHERE year = '2023' AND month = '01';
SELECT 'divvy_trips_2024' as table_name, COUNT(*) as row_count FROM divvy_bronze.divvy_trips WHERE year = '2024' AND month = '01';
SELECT 'weather_chicago_2023' as table_name, COUNT(*) as row_count FROM divvy_bronze.weather_data WHERE location = 'chicago' AND year = '2023' AND month = '01';
SELECT 'weather_evanston_2024' as table_name, COUNT(*) as row_count FROM divvy_bronze.weather_data WHERE location = 'evanston' AND year = '2024' AND month = '01';

-- Sample data preview
SELECT 'Sample 2023 trip data:' as info;
SELECT * FROM divvy_bronze.divvy_trips WHERE year = '2023' AND month = '01' LIMIT 3;

SELECT 'Sample 2024 trip data:' as info;
SELECT * FROM divvy_bronze.divvy_trips WHERE year = '2024' AND month = '01' LIMIT 3;
