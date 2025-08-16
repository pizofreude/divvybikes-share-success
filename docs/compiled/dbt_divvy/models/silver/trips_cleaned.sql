

-- Silver layer: Clean and standardize trip data
WITH cleaned_trips AS (
  SELECT
    -- Primary identifiers
    ride_id,
    TRIM(UPPER(rideable_type)) AS rideable_type,
    
    -- Timestamps (ensure proper UTC conversion)
    started_at,
    ended_at,
    
    -- Station information (clean whitespace)
    TRIM(start_station_name) AS start_station_name,
    TRIM(start_station_id) AS start_station_id,
    TRIM(end_station_name) AS end_station_name,
    TRIM(end_station_id) AS end_station_id,
    
    -- Coordinates
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    
    -- Member type standardization
    CASE 
      WHEN LOWER(TRIM(member_casual)) = 'member' THEN 'member'
      WHEN LOWER(TRIM(member_casual)) = 'casual' THEN 'casual'
      ELSE 'unknown'
    END AS member_casual,
    
    -- Calculated fields
    EXTRACT(EPOCH FROM (ended_at - started_at)) / 60.0 AS ride_length_minutes,
    EXTRACT(DOW FROM started_at) AS day_of_week,
    EXTRACT(HOUR FROM started_at) AS hour_of_day,
    EXTRACT(MONTH FROM started_at) AS month,
    EXTRACT(YEAR FROM started_at) AS year,
    DATE(started_at) AS ride_date,
    
    -- Weekend flag
    CASE 
      WHEN EXTRACT(DOW FROM started_at) IN (0, 6) THEN TRUE
      ELSE FALSE
    END AS is_weekend,
    
    -- Season calculation
    
  CASE 
    WHEN EXTRACT(MONTH FROM started_at) IN (12, 1, 2) THEN 'Winter'
    WHEN EXTRACT(MONTH FROM started_at) IN (3, 4, 5) THEN 'Spring'
    WHEN EXTRACT(MONTH FROM started_at) IN (6, 7, 8) THEN 'Summer'
    WHEN EXTRACT(MONTH FROM started_at) IN (9, 10, 11) THEN 'Fall'
    ELSE 'Unknown'
  END
 AS season,
    
    -- Round trip indicator
    CASE 
      WHEN start_station_id = end_station_id THEN TRUE
      ELSE FALSE
    END AS is_round_trip,
    
    -- Distance calculation using haversine formula
    
  -- Calculate haversine distance between two coordinates in kilometers
  (
    6371 * acos(
      cos(radians(start_lat)) * 
      cos(radians(end_lat)) * 
      cos(radians(end_lng) - radians(start_lng)) + 
      sin(radians(start_lat)) * 
      sin(radians(end_lat))
    )
  )
 AS trip_distance_km

  FROM "divvy"."divvy_bronze"."divvy_trips"
  
  WHERE 
    -- Data quality filters
    ride_id IS NOT NULL
    AND started_at IS NOT NULL
    AND ended_at IS NOT NULL
    AND started_at < ended_at
    AND start_station_id IS NOT NULL
    AND end_station_id IS NOT NULL
    -- Filter out extreme outliers
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) BETWEEN 60 AND 86400  -- 1 minute to 24 hours
    AND start_lat BETWEEN 41.0 AND 43.0  -- Reasonable Chicago area bounds
    AND start_lng BETWEEN -89.0 AND -87.0
    AND end_lat BETWEEN 41.0 AND 43.0
    AND end_lng BETWEEN -89.0 AND -87.0
    AND member_casual IN ('member', 'casual')
)

SELECT *
FROM cleaned_trips