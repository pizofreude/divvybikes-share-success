{{
  config(
    materialized='table',
    dist_key='analysis_date',
    sort_key='analysis_date',
    description='Daily behavioral analysis comparing member vs casual usage patterns'
  )
}}

-- Gold layer: Daily behavioral analysis for member vs casual comparison
WITH daily_usage_patterns AS (
  SELECT
    ride_date AS analysis_date,
    member_casual,
    season,
    is_weekend,
    weather_suitability,
    temperature_category,
    
    -- Trip volume metrics
    COUNT(*) AS daily_trips,
    COUNT(DISTINCT start_station_id) AS unique_start_stations,
    COUNT(DISTINCT end_station_id) AS unique_end_stations,
    
    -- Duration metrics
    AVG(ride_length_minutes) AS avg_trip_duration,
    
    -- Distance metrics
    AVG(trip_distance_km) AS avg_trip_distance,
    
    -- Bike type preferences
    COUNT(CASE WHEN rideable_type = 'CLASSIC_BIKE' THEN 1 END) AS classic_bike_trips,
    COUNT(CASE WHEN rideable_type = 'ELECTRIC_BIKE' THEN 1 END) AS electric_bike_trips,
    COUNT(CASE WHEN rideable_type = 'DOCKED_BIKE' THEN 1 END) AS docked_bike_trips,
    
    -- Time pattern analysis
    COUNT(CASE WHEN time_segment = 'Morning Commute' THEN 1 END) AS morning_commute_trips,
    COUNT(CASE WHEN time_segment = 'Evening Commute' THEN 1 END) AS evening_commute_trips,
    COUNT(CASE WHEN time_segment = 'Midday' THEN 1 END) AS midday_trips,
    COUNT(CASE WHEN time_segment = 'Evening Leisure' THEN 1 END) AS evening_leisure_trips,
    
    -- Revenue metrics
    SUM(total_trip_revenue_with_tax) AS daily_revenue,
    AVG(total_trip_revenue_with_tax) AS avg_revenue_per_trip,
    
    -- Behavioral indicators
    COUNT(CASE WHEN is_round_trip THEN 1 END) AS round_trips,
    COUNT(CASE WHEN usage_profile LIKE '%High Usage%' THEN 1 END) AS high_usage_trips,
    
    -- Area type preferences
    COUNT(CASE WHEN start_area_type = 'Downtown' THEN 1 END) AS downtown_start_trips,
    COUNT(CASE WHEN start_area_type = 'Urban Core' THEN 1 END) AS urban_core_start_trips

  FROM {{ ref('trips_enhanced') }}
  GROUP BY 1, 2, 3, 4, 5, 6
),

daily_comparisons AS (
  SELECT
    analysis_date,
    season,
    is_weekend,
    weather_suitability,
    temperature_category,
    
    -- Member metrics
    MAX(CASE WHEN member_casual = 'member' THEN daily_trips END) AS member_trips,
    MAX(CASE WHEN member_casual = 'member' THEN avg_trip_duration END) AS member_avg_duration,
    MAX(CASE WHEN member_casual = 'member' THEN avg_trip_distance END) AS member_avg_distance,
    MAX(CASE WHEN member_casual = 'member' THEN daily_revenue END) AS member_revenue,
    MAX(CASE WHEN member_casual = 'member' THEN morning_commute_trips + evening_commute_trips END) AS member_commute_trips,
    MAX(CASE WHEN member_casual = 'member' THEN round_trips END) AS member_round_trips,
    
    -- Casual metrics
    MAX(CASE WHEN member_casual = 'casual' THEN daily_trips END) AS casual_trips,
    MAX(CASE WHEN member_casual = 'casual' THEN avg_trip_duration END) AS casual_avg_duration,
    MAX(CASE WHEN member_casual = 'casual' THEN avg_trip_distance END) AS casual_avg_distance,
    MAX(CASE WHEN member_casual = 'casual' THEN daily_revenue END) AS casual_revenue,
    MAX(CASE WHEN member_casual = 'casual' THEN morning_commute_trips + evening_commute_trips END) AS casual_commute_trips,
    MAX(CASE WHEN member_casual = 'casual' THEN round_trips END) AS casual_round_trips,
    MAX(CASE WHEN member_casual = 'casual' THEN high_usage_trips END) AS casual_high_usage_trips,
    
    -- Bike type preferences
    MAX(CASE WHEN member_casual = 'member' THEN electric_bike_trips END) AS member_ebike_trips,
    MAX(CASE WHEN member_casual = 'casual' THEN electric_bike_trips END) AS casual_ebike_trips

  FROM daily_usage_patterns
  GROUP BY 1, 2, 3, 4, 5
),

final_analysis AS (
  SELECT
    *,
    
    -- Calculated ratios and differences
    COALESCE(member_trips, 0) + COALESCE(casual_trips, 0) AS total_daily_trips,
    
    CASE 
      WHEN COALESCE(member_trips, 0) > 0 AND COALESCE(casual_trips, 0) > 0 THEN
        ROUND(casual_avg_duration / member_avg_duration, 2)
      ELSE NULL
    END AS duration_ratio_casual_to_member,
    
    CASE 
      WHEN COALESCE(member_trips, 0) > 0 AND COALESCE(casual_trips, 0) > 0 THEN
        ROUND(casual_avg_distance / member_avg_distance, 2)
      ELSE NULL
    END AS distance_ratio_casual_to_member,
    
    -- Conversion indicators
    CASE 
      WHEN COALESCE(casual_high_usage_trips, 0) > 0 AND COALESCE(casual_trips, 0) > 0 THEN
        ROUND(100.0 * casual_high_usage_trips / casual_trips, 2)
      ELSE 0
    END AS casual_high_usage_percentage,
    
    -- Commute pattern analysis
    CASE 
      WHEN COALESCE(casual_trips, 0) > 0 THEN
        ROUND(100.0 * COALESCE(casual_commute_trips, 0) / casual_trips, 2)
      ELSE 0
    END AS casual_commute_percentage,
    
    CASE 
      WHEN COALESCE(member_trips, 0) > 0 THEN
        ROUND(100.0 * COALESCE(member_commute_trips, 0) / member_trips, 2)
      ELSE 0
    END AS member_commute_percentage

  FROM daily_comparisons
)

SELECT *
FROM final_analysis
ORDER BY analysis_date DESC
