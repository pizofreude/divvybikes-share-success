{{
  config(
    materialized='view',
    description='Conversion opportunity dashboard for identifying high-potential casual riders'
  )
}}

-- Mart: Conversion opportunity analysis
WITH conversion_metrics AS (
  SELECT
    'Daily Averages' AS metric_period,
    
    -- Overall conversion metrics
    AVG(COALESCE(casual_trips, 0)) AS avg_daily_casual_trips,
    AVG(COALESCE(member_trips, 0)) AS avg_daily_member_trips,
    AVG(casual_high_usage_percentage) AS avg_casual_high_usage_pct,
    
    -- Revenue impact analysis
    AVG(COALESCE(casual_revenue, 0)) AS avg_daily_casual_revenue,
    AVG(COALESCE(member_revenue, 0)) AS avg_daily_member_revenue,
    
    -- Behavioral patterns
    AVG(casual_commute_percentage) AS avg_casual_commute_pct,
    AVG(member_commute_percentage) AS avg_member_commute_pct,
    
    -- Weather impact
    COUNT(CASE WHEN weather_suitability IN ('Good', 'Excellent') THEN 1 END) AS good_weather_days,
    COUNT(*) AS total_analysis_days

  FROM {{ ref('behavioral_analysis') }}
  
  UNION ALL
  
  SELECT
    'Weekends' AS metric_period,
    
    -- Weekend patterns only
    AVG(CASE WHEN is_weekend THEN COALESCE(casual_trips, 0) ELSE NULL END) AS avg_daily_casual_trips,
    AVG(CASE WHEN is_weekend THEN COALESCE(member_trips, 0) ELSE NULL END) AS avg_daily_member_trips,
    AVG(CASE WHEN is_weekend THEN casual_high_usage_percentage ELSE NULL END) AS avg_casual_high_usage_pct,
    
    AVG(CASE WHEN is_weekend THEN COALESCE(casual_revenue, 0) ELSE NULL END) AS avg_daily_casual_revenue,
    AVG(CASE WHEN is_weekend THEN COALESCE(member_revenue, 0) ELSE NULL END) AS avg_daily_member_revenue,
    
    AVG(CASE WHEN is_weekend THEN casual_commute_percentage ELSE NULL END) AS avg_casual_commute_pct,
    AVG(CASE WHEN is_weekend THEN member_commute_percentage ELSE NULL END) AS avg_member_commute_pct,
    
    COUNT(CASE WHEN is_weekend AND weather_suitability IN ('Good', 'Excellent') THEN 1 END) AS good_weather_days,
    COUNT(CASE WHEN is_weekend THEN 1 END) AS total_analysis_days

  FROM {{ ref('behavioral_analysis') }}
  
  UNION ALL
  
  SELECT
    'Weekdays' AS metric_period,
    
    -- Weekday patterns only
    AVG(CASE WHEN NOT is_weekend THEN COALESCE(casual_trips, 0) ELSE NULL END) AS avg_daily_casual_trips,
    AVG(CASE WHEN NOT is_weekend THEN COALESCE(member_trips, 0) ELSE NULL END) AS avg_daily_member_trips,
    AVG(CASE WHEN NOT is_weekend THEN casual_high_usage_percentage ELSE NULL END) AS avg_casual_high_usage_pct,
    
    AVG(CASE WHEN NOT is_weekend THEN COALESCE(casual_revenue, 0) ELSE NULL END) AS avg_daily_casual_revenue,
    AVG(CASE WHEN NOT is_weekend THEN COALESCE(member_revenue, 0) ELSE NULL END) AS avg_daily_member_revenue,
    
    AVG(CASE WHEN NOT is_weekend THEN casual_commute_percentage ELSE NULL END) AS avg_casual_commute_pct,
    AVG(CASE WHEN NOT is_weekend THEN member_commute_percentage ELSE NULL END) AS avg_member_commute_pct,
    
    COUNT(CASE WHEN NOT is_weekend AND weather_suitability IN ('Good', 'Excellent') THEN 1 END) AS good_weather_days,
    COUNT(CASE WHEN NOT is_weekend THEN 1 END) AS total_analysis_days

  FROM {{ ref('behavioral_analysis') }}
  
  UNION ALL
  
  SELECT
    'Seasonal: ' || season AS metric_period,
    
    AVG(COALESCE(casual_trips, 0)) AS avg_daily_casual_trips,
    AVG(COALESCE(member_trips, 0)) AS avg_daily_member_trips,
    AVG(casual_high_usage_percentage) AS avg_casual_high_usage_pct,
    
    AVG(COALESCE(casual_revenue, 0)) AS avg_daily_casual_revenue,
    AVG(COALESCE(member_revenue, 0)) AS avg_daily_member_revenue,
    
    AVG(casual_commute_percentage) AS avg_casual_commute_pct,
    AVG(member_commute_percentage) AS avg_member_commute_pct,
    
    COUNT(CASE WHEN weather_suitability IN ('Good', 'Excellent') THEN 1 END) AS good_weather_days,
    COUNT(*) AS total_analysis_days

  FROM {{ ref('behavioral_analysis') }}
  WHERE season IS NOT NULL
  GROUP BY season
),

station_opportunities AS (
  SELECT
    'Top 10 Conversion Stations' AS insight_category,
    station_name AS detail,
    conversion_potential_score AS value,
    high_value_casual_percentage AS secondary_value,
    conversion_priority AS priority_level
    
  FROM {{ ref('station_performance') }}
  WHERE conversion_potential_score > 0
  ORDER BY conversion_potential_score DESC
  LIMIT 10
)

SELECT 
  metric_period,
  ROUND(COALESCE(avg_daily_casual_trips, 0), 1) AS avg_casual_trips_per_day,
  ROUND(COALESCE(avg_daily_member_trips, 0), 1) AS avg_member_trips_per_day,
  ROUND(COALESCE(avg_casual_high_usage_pct, 0), 2) AS casual_high_usage_rate,
  ROUND(COALESCE(avg_daily_casual_revenue, 0), 2) AS avg_casual_revenue_per_day,
  ROUND(COALESCE(avg_casual_commute_pct, 0), 2) AS casual_commute_usage_rate,
  ROUND(
    CASE 
      WHEN total_analysis_days > 0 THEN 100.0 * good_weather_days / total_analysis_days
      ELSE 0 
    END, 1
  ) AS good_weather_percentage,
  
  -- Conversion opportunity indicators
  CASE 
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 15 THEN 'High Conversion Potential'
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 10 THEN 'Medium Conversion Potential'
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 5 THEN 'Low Conversion Potential'
    ELSE 'Minimal Conversion Potential'
  END AS conversion_assessment,
  
  -- Recommended actions
  CASE 
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 15 AND COALESCE(avg_casual_commute_pct, 0) > 20 THEN 'Target Commuter Conversion Campaign'
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 10 AND COALESCE(avg_casual_commute_pct, 0) < 10 THEN 'Target Leisure-to-Member Campaign'
    WHEN COALESCE(avg_casual_high_usage_pct, 0) > 5 THEN 'General Awareness Campaign'
    ELSE 'Focus on Usage Growth First'
  END AS recommended_strategy

FROM conversion_metrics
ORDER BY 
  CASE 
    WHEN metric_period = 'Daily Averages' THEN 1
    WHEN metric_period = 'Weekend vs Weekday' THEN 2
    ELSE 3
  END
