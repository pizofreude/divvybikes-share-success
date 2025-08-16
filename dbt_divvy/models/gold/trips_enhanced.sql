{{
  config(
    materialized='table',
    dist_key='ride_id',
    sort_key='ride_date',
    description='Comprehensive trip data with weather integration and revenue calculations'
  )
}}

-- Gold layer: Enhanced trip data with weather and revenue calculations
WITH trip_weather AS (
  SELECT
    t.*,
    -- Weather data joined by date
    w.temperature_2m_mean AS temperature,
    w.apparent_temperature_mean AS feels_like_temperature,
    w.precipitation_sum,
    w.rain_sum,
    w.wind_speed_10m_max AS wind_speed,
    w.cloud_cover_mean AS cloud_cover,
    w.temperature_category,
    w.precipitation_category,
    w.weather_suitability,
    
    -- Station information
    ss.station_name AS start_station_name_clean,
    ss.area_type AS start_area_type,
    ss.capacity_category AS start_capacity_category,
    es.station_name AS end_station_name_clean,
    es.area_type AS end_area_type,
    es.capacity_category AS end_capacity_category,
    
    -- Revenue calculations based on 2024-2025 pricing
    CASE 
      WHEN t.member_casual = 'member' THEN
        -- Annual members: $0.19/minute after 45 minutes
        CASE 
          WHEN t.ride_length_minutes <= 45 THEN 0
          ELSE CEILING(t.ride_length_minutes - 45) * {{ var('overage_rate_per_minute') }}
        END
      WHEN t.member_casual = 'casual' THEN
        -- Day pass users: $0.19/minute after 3 hours (180 minutes)
        CASE 
          WHEN t.ride_length_minutes <= 180 THEN 0
          ELSE CEILING(t.ride_length_minutes - 180) * {{ var('overage_rate_per_minute') }}
        END
      ELSE 0
    END AS overage_fee,
    
    -- Lost/stolen bike fee for trips over 24 hours
    CASE 
      WHEN t.ride_length_minutes > 1440 THEN {{ var('lost_stolen_bike_fee') }}
      ELSE 0
    END AS lost_stolen_fee,
    
    -- Estimated base revenue (for casual riders only - members pay annually)
    CASE 
      WHEN t.member_casual = 'casual' THEN {{ var('day_pass_price') }}
      ELSE 0
    END AS base_revenue

  FROM {{ ref('trips_cleaned') }} t
  LEFT JOIN {{ ref('weather_cleaned') }} w ON t.ride_date = w.weather_date
  LEFT JOIN {{ ref('stations_cleaned') }} ss ON t.start_station_id = ss.station_id
  LEFT JOIN {{ ref('stations_cleaned') }} es ON t.end_station_id = es.station_id
),

final_calculations AS (
  SELECT
    *,
    -- Total revenue per trip
    base_revenue + overage_fee + lost_stolen_fee AS total_trip_revenue,
    
    -- Tax calculation (applied to total revenue)
    (base_revenue + overage_fee + lost_stolen_fee) * {{ var('sales_tax_rate') }} AS sales_tax,
    
    -- Final revenue including tax
    (base_revenue + overage_fee + lost_stolen_fee) * (1 + {{ var('sales_tax_rate') }}) AS total_trip_revenue_with_tax,
    
    -- Usage patterns for conversion analysis
    CASE 
      WHEN member_casual = 'casual' AND ride_length_minutes > 180 THEN 'High Usage Casual'
      WHEN member_casual = 'casual' AND ride_length_minutes BETWEEN 45 AND 180 THEN 'Medium Usage Casual'
      WHEN member_casual = 'casual' AND ride_length_minutes <= 45 THEN 'Low Usage Casual'
      WHEN member_casual = 'member' AND ride_length_minutes > 45 THEN 'High Usage Member'
      WHEN member_casual = 'member' AND ride_length_minutes <= 45 THEN 'Regular Member'
      ELSE 'Unknown'
    END AS usage_profile,
    
    -- Time-based segments for marketing
    CASE 
      WHEN hour_of_day BETWEEN 6 AND 9 THEN 'Morning Commute'
      WHEN hour_of_day BETWEEN 10 AND 15 THEN 'Midday'
      WHEN hour_of_day BETWEEN 16 AND 19 THEN 'Evening Commute'
      WHEN hour_of_day BETWEEN 20 AND 23 THEN 'Evening Leisure'
      ELSE 'Late Night/Early Morning'
    END AS time_segment

  FROM trip_weather
)

SELECT *
FROM final_calculations
