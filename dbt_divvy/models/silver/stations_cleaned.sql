{{
  config(
    materialized='table',
    dist_key='station_id',
    sort_key='station_id',
    description='Cleaned and standardized station information'
  )
}}

-- Silver layer: Clean and standardize station data derived from trips
WITH station_data_from_trips AS (
  -- Get unique stations from start stations
  SELECT DISTINCT
    TRIM(REPLACE(start_station_id, '"', '')) AS station_id,
    TRIM(REPLACE(start_station_name, '"', '')) AS station_name,
    start_lat AS station_lat,
    start_lng AS station_lng
  FROM {{ source('divvy_bronze', 'divvy_trips') }}
  WHERE start_station_id IS NOT NULL 
    AND start_station_name IS NOT NULL
    AND start_lat IS NOT NULL 
    AND start_lng IS NOT NULL
    
  UNION
  
  -- Get unique stations from end stations
  SELECT DISTINCT
    TRIM(REPLACE(end_station_id, '"', '')) AS station_id,
    TRIM(REPLACE(end_station_name, '"', '')) AS station_name,
    end_lat AS station_lat,
    end_lng AS station_lng
  FROM {{ source('divvy_bronze', 'divvy_trips') }}
  WHERE end_station_id IS NOT NULL 
    AND end_station_name IS NOT NULL
    AND end_lat IS NOT NULL 
    AND end_lng IS NOT NULL
),

cleaned_stations AS (
  SELECT
    -- Primary identifiers
    station_id,
    -- Use first station name for this ID (they should be consistent)
    MIN(station_name) AS station_name,
    MIN(station_name) AS station_short_name,
    
    -- Use average coordinates for consistency
    AVG(station_lat) AS station_lat,
    AVG(station_lng) AS station_lng,
    
    -- Default capacity (since we don't have this data)
    25 AS capacity,
    
    -- Count trips for this station
    COUNT(*) AS trip_count

  FROM station_data_from_trips
  
  WHERE 
    station_id IS NOT NULL
    AND station_name IS NOT NULL
    AND station_lat IS NOT NULL
    AND station_lng IS NOT NULL
    -- Basic coordinate validation for Chicago area
    AND station_lat BETWEEN 41.0 AND 43.0
    AND station_lng BETWEEN -89.0 AND -87.0
    
  GROUP BY station_id
),

final_stations AS (
  SELECT
    station_id,
    station_name,
    station_short_name,
    station_lat,
    station_lng,
    capacity,
    trip_count,
    
    -- Derived location features
    CASE 
      WHEN station_lat BETWEEN 41.85 AND 41.95 AND station_lng BETWEEN -87.70 AND -87.60 THEN 'Downtown'
      WHEN station_lat BETWEEN 41.75 AND 42.05 AND station_lng BETWEEN -87.80 AND -87.55 THEN 'Urban Core'
      WHEN station_lat BETWEEN 41.65 AND 42.15 AND station_lng BETWEEN -87.90 AND -87.50 THEN 'Greater Metro'
      ELSE 'Outer Area'
    END AS area_type,
    
    -- Capacity categories (using default)
    'Medium' AS capacity_category

  FROM cleaned_stations
)

SELECT *
FROM final_stations
