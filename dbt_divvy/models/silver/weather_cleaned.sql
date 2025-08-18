{{
  config(
    materialized='table',
    dist_key='weather_date',
    sort_key='weather_date',
    description='Cleaned weather data with derived features for analysis'
  )
}}

-- Silver layer: Clean and standardize weather data
WITH cleaned_weather AS (
  SELECT
    -- Primary date identifier
    time AS weather_date,
    
    -- Temperature metrics (Celsius)
    temperature_2m_max,
    temperature_2m_min,
    temperature_2m_mean,
    apparent_temperature_max,
    apparent_temperature_min,
    apparent_temperature_mean,
    
    -- Precipitation metrics (mm and cm)
    COALESCE(precipitation_sum, 0) AS precipitation_sum,
    COALESCE(rain_sum, 0) AS rain_sum,
    COALESCE(snowfall_sum, 0) AS snowfall_sum,
    
    -- Wind metrics (km/h and degrees)
    wind_speed_10m_max,
    wind_gusts_10m_max,
    wind_direction_10m_dominant,
    
    -- Cloud cover (%)
    cloud_cover_mean,
    
    -- Derived temperature features
    (temperature_2m_max + temperature_2m_min) / 2.0 AS avg_temperature,
    temperature_2m_max - temperature_2m_min AS temperature_range,
    
    -- Temperature categories for analysis
    CASE 
      WHEN temperature_2m_mean < -10 THEN 'Very Cold'
      WHEN temperature_2m_mean < 0 THEN 'Cold'
      WHEN temperature_2m_mean < 10 THEN 'Cool'
      WHEN temperature_2m_mean < 20 THEN 'Mild'
      WHEN temperature_2m_mean < 30 THEN 'Warm'
      ELSE 'Hot'
    END AS temperature_category,
    
    -- Precipitation categories
    CASE 
      WHEN precipitation_sum = 0 THEN 'No Rain'
      WHEN precipitation_sum <= 2.5 THEN 'Light Rain'
      WHEN precipitation_sum <= 10 THEN 'Moderate Rain'
      WHEN precipitation_sum <= 50 THEN 'Heavy Rain'
      ELSE 'Extreme Rain'
    END AS precipitation_category,
    
    -- Weather suitability for biking
    CASE 
      WHEN temperature_2m_mean < -5 OR precipitation_sum > 10 OR wind_speed_10m_max > 30 THEN 'Poor'
      WHEN temperature_2m_mean < 5 OR precipitation_sum > 2.5 OR wind_speed_10m_max > 20 THEN 'Fair'
      WHEN temperature_2m_mean BETWEEN 5 AND 25 AND precipitation_sum <= 2.5 AND wind_speed_10m_max <= 20 THEN 'Good'
      ELSE 'Excellent'
    END AS weather_suitability,
    
    -- Seasonal indicators
    EXTRACT(MONTH FROM time) AS month,
    EXTRACT(YEAR FROM time) AS year,
    {{ get_season('EXTRACT(MONTH FROM time)') }} AS season

  FROM {{ source('divvy_bronze', 'weather_data') }}
  
  WHERE 
    location = 'chicago'  -- Focus on Chicago weather for bike trip analysis
    AND time IS NOT NULL
    AND temperature_2m_mean IS NOT NULL
    -- Basic data quality checks
    AND temperature_2m_max >= temperature_2m_min
    AND precipitation_sum >= 0
    AND wind_speed_10m_max >= 0
)

SELECT *
FROM cleaned_weather
