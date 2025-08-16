
  
    

  create  table
    "divvy"."public_silver"."stations_cleaned__dbt_tmp"
    
    
    
  as (
    

-- Silver layer: Clean and standardize station data
WITH cleaned_stations AS (
  SELECT
    -- Primary identifiers
    station_id,
    legacy_id,
    
    -- Station names (cleaned)
    TRIM(name) AS station_name,
    TRIM(short_name) AS station_short_name,
    
    -- Location coordinates
    lat AS station_lat,
    lon AS station_lng,
    
    -- Station capacity
    capacity,
    
    -- Derived location features
    CASE 
      WHEN lat BETWEEN 41.85 AND 41.95 AND lon BETWEEN -87.70 AND -87.60 THEN 'Downtown'
      WHEN lat BETWEEN 41.75 AND 42.05 AND lon BETWEEN -87.80 AND -87.55 THEN 'Urban Core'
      WHEN lat BETWEEN 41.65 AND 42.15 AND lon BETWEEN -87.90 AND -87.50 THEN 'Greater Metro'
      ELSE 'Outer Area'
    END AS area_type,
    
    -- Capacity categories
    CASE 
      WHEN capacity <= 15 THEN 'Small'
      WHEN capacity <= 25 THEN 'Medium'
      WHEN capacity <= 35 THEN 'Large'
      ELSE 'Extra Large'
    END AS capacity_category

  FROM "divvy"."divvy_bronze"."gbfs_stations"
  
  WHERE 
    station_id IS NOT NULL
    AND name IS NOT NULL
    AND lat IS NOT NULL
    AND lon IS NOT NULL
    -- Basic coordinate validation for Chicago area
    AND lat BETWEEN 41.0 AND 43.0
    AND lon BETWEEN -89.0 AND -87.0
    AND capacity > 0
)

SELECT *
FROM cleaned_stations
  );
  