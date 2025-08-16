{{
  config(
    materialized='table',
    dist_key='station_id',
    sort_key=['station_id', 'analysis_date'],
    description='Station-level performance metrics and conversion potential analysis'
  )
}}

-- Gold layer: Station performance analysis
WITH daily_station_stats AS (
  SELECT
    start_station_id AS station_id,
    ride_date AS analysis_date,
    member_casual,
    
    -- Trip counts
    COUNT(*) AS daily_trips,
    AVG(ride_length_minutes) AS avg_trip_duration,
    SUM(total_trip_revenue_with_tax) AS daily_revenue,
    
    -- Usage patterns
    COUNT(CASE WHEN time_segment = 'Morning Commute' THEN 1 END) AS morning_commute_trips,
    COUNT(CASE WHEN time_segment = 'Evening Commute' THEN 1 END) AS evening_commute_trips,
    COUNT(CASE WHEN is_weekend THEN 1 END) AS weekend_trips,
    COUNT(CASE WHEN is_round_trip THEN 1 END) AS round_trips,
    
    -- Weather correlation
    AVG(temperature) AS avg_temperature,
    AVG(precipitation_sum) AS avg_precipitation,
    
    -- High-value casual users (conversion prospects)
    COUNT(CASE WHEN member_casual = 'casual' AND ride_length_minutes > 180 THEN 1 END) AS high_usage_casual_trips

  FROM {{ ref('trips_enhanced') }}
  GROUP BY 1, 2, 3
),

station_aggregates AS (
  SELECT
    station_id,
    
    -- Overall metrics
    COUNT(DISTINCT analysis_date) AS active_days,
    SUM(daily_trips) AS total_trips,
    AVG(daily_trips) AS avg_daily_trips,
    AVG(avg_trip_duration) AS avg_trip_duration,
    SUM(daily_revenue) AS total_revenue,
    
    -- Member vs casual breakdown
    SUM(CASE WHEN member_casual = 'member' THEN daily_trips ELSE 0 END) AS member_trips,
    SUM(CASE WHEN member_casual = 'casual' THEN daily_trips ELSE 0 END) AS casual_trips,
    
    -- Conversion metrics
    SUM(high_usage_casual_trips) AS high_value_casual_trips,
    ROUND(
      100.0 * SUM(high_usage_casual_trips) / NULLIF(SUM(CASE WHEN member_casual = 'casual' THEN daily_trips END), 0),
      2
    ) AS high_value_casual_percentage,
    
    -- Usage pattern indicators
    SUM(morning_commute_trips) AS total_morning_commute,
    SUM(evening_commute_trips) AS total_evening_commute,
    SUM(weekend_trips) AS total_weekend_trips,
    SUM(round_trips) AS total_round_trips,
    
    -- Weather sensitivity
    AVG(avg_temperature) AS avg_temperature,
    AVG(avg_precipitation) AS avg_precipitation,
    
    -- Conversion potential score (0-100)
    ROUND(
      LEAST(100, (
        -- Base score from casual usage volume (40%)
        (SUM(CASE WHEN member_casual = 'casual' THEN daily_trips ELSE 0 END) * 0.4 / 10) +
        -- High-value casual percentage (30%)
        (COALESCE(SUM(high_usage_casual_trips) * 30.0 / NULLIF(SUM(CASE WHEN member_casual = 'casual' THEN daily_trips END), 0), 0)) +
        -- Commute pattern bonus (20%)
        (LEAST(20, (SUM(morning_commute_trips) + SUM(evening_commute_trips)) * 20.0 / NULLIF(SUM(daily_trips), 0) * 100)) +
        -- Round trip bonus (10%)
        (LEAST(10, SUM(round_trips) * 10.0 / NULLIF(SUM(daily_trips), 0) * 100))
      )),
      2
    ) AS conversion_potential_score

  FROM daily_station_stats
  GROUP BY station_id
),

final_with_station_info AS (
  SELECT
    sa.*,
    s.station_name,
    s.station_lat,
    s.station_lng,
    s.area_type,
    s.capacity_category,
    s.capacity,
    
    -- Performance categories
    CASE 
      WHEN sa.avg_daily_trips >= 50 THEN 'High Volume'
      WHEN sa.avg_daily_trips >= 20 THEN 'Medium Volume'
      WHEN sa.avg_daily_trips >= 5 THEN 'Low Volume'
      ELSE 'Minimal Volume'
    END AS volume_category,
    
    -- Conversion priority
    CASE 
      WHEN sa.conversion_potential_score >= 80 THEN 'Very High Priority'
      WHEN sa.conversion_potential_score >= 60 THEN 'High Priority'
      WHEN sa.conversion_potential_score >= 40 THEN 'Medium Priority'
      WHEN sa.conversion_potential_score >= 20 THEN 'Low Priority'
      ELSE 'Minimal Priority'
    END AS conversion_priority

  FROM station_aggregates sa
  LEFT JOIN {{ ref('stations_cleaned') }} s ON sa.station_id = s.station_id
)

SELECT *
FROM final_with_station_info
ORDER BY conversion_potential_score DESC
