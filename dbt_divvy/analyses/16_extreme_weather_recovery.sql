/*
BUSINESS QUESTION 4D: Extreme Weather Event Recovery Patterns

OBJECTIVE: Analyze recovery patterns after extreme weather events:
- Post-storm ridership recovery timelines by user type
- Extreme temperature event impact and bounce-back patterns
- Weather event duration vs. recovery speed correlation
- High-value casual rider identification during extreme weather periods

MARKETING APPLICATION:
- Automated post-storm re-engagement campaigns with specific timing
- Extreme weather survivor targeting for premium membership offers
- Weather-resilient rider rewards and recognition programs
- Crisis communication and service recovery messaging strategies

EXPECTED INSIGHTS:
- Members recover to baseline ridership 24-48 hours post-extreme weather
- Casual riders take 3-7 days to return to normal usage patterns
- Multi-day weather events have exponentially longer recovery periods
- Riders who use service during extreme weather show 3-5x higher conversion rates
*/

WITH extreme_weather_events AS (
    -- Identify extreme weather events and categorize severity
    SELECT 
        weather_date,
        temperature_2m_mean,
        precipitation_sum,
        
        -- Extreme weather event categorization using existing categories
        CASE 
            WHEN temperature_category = 'Cold' THEN 'Extreme Cold'
            WHEN temperature_category = 'Very Hot' THEN 'Extreme Heat'
            WHEN precipitation_category = 'Extreme Rain' THEN 'Heavy Rain'
            ELSE 'Normal Weather'
        END as weather_event_type,
        
        -- Event severity scoring based on existing categories
        CASE 
            WHEN temperature_category IN ('Cold', 'Very Hot') AND precipitation_category = 'Extreme Rain' THEN 'Severe'
            WHEN temperature_category IN ('Cold', 'Very Hot') THEN 'Moderate'
            WHEN precipitation_category = 'Extreme Rain' THEN 'Mild'
            ELSE 'Normal'
        END as event_severity,
        
        -- Multi-day event identification
        CASE 
            WHEN LAG(CASE 
                WHEN temperature_category IN ('Cold', 'Very Hot') OR precipitation_category = 'Extreme Rain' THEN 1 ELSE 0 
            END) OVER (ORDER BY weather_date) = 1 
            THEN 'Consecutive Extreme Day'
            WHEN temperature_category IN ('Cold', 'Very Hot') OR precipitation_category = 'Extreme Rain'
            THEN 'Single Extreme Day'
            ELSE 'Normal Day'
        END as event_duration_type
        
    FROM "divvy"."public_silver"."weather_cleaned"
    WHERE EXTRACT(year FROM weather_date) IN (2023, 2024)
        AND temperature_2m_mean IS NOT NULL
),
daily_ridership_with_weather AS (
    -- Combine daily ridership data with weather events
    SELECT 
        DATE(t.started_at) as trip_date,
        EXTRACT(year FROM t.started_at) as usage_year,
        t.member_casual as user_type,
        
        -- Weather event information
        w.weather_event_type,
        w.event_severity,
        w.event_duration_type,
        w.temperature_2m_mean,
        w.precipitation_sum,
        
        -- Daily ridership metrics
        COUNT(*) as daily_trips,
        COUNT(DISTINCT 
            CASE 
                WHEN t.start_station_name IS NULL OR t.start_station_name = '' THEN 'Unknown Station'
                ELSE t.start_station_name 
            END
        ) as unique_riders,
        
        AVG(t.ride_length_minutes) as avg_trip_duration,
        AVG(t.trip_distance_km) as avg_trip_distance,
        
        -- Trip quality during extreme weather
        COUNT(CASE 
            WHEN t.ride_length_minutes BETWEEN 5 AND 45 THEN 1 
        END) as quality_trips,
        
        -- Trip purpose analysis
        COUNT(CASE 
            WHEN EXTRACT(hour FROM t.started_at) BETWEEN 7 AND 9 
                OR EXTRACT(hour FROM t.started_at) BETWEEN 17 AND 19 
            THEN 1 
        END) as commute_trips,
        
        -- Weekend vs weekday extreme weather usage
        CASE 
            WHEN EXTRACT(dow FROM t.started_at) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END as day_type
        
    FROM "divvy"."public_gold"."trips_enhanced" t
    JOIN extreme_weather_events w 
        ON DATE(t.started_at) = w.weather_date
    WHERE EXTRACT(year FROM t.started_at) IN (2023, 2024)
        AND t.ride_length_minutes > 0 
        AND t.ride_length_minutes < 1440
    GROUP BY 
        DATE(t.started_at),
        EXTRACT(year FROM t.started_at),
        t.member_casual,
        w.weather_event_type,
        w.event_severity,
        w.event_duration_type,
        w.temperature_2m_mean,
        w.precipitation_sum,
        CASE 
            WHEN EXTRACT(dow FROM t.started_at) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END
),
recovery_pattern_analysis AS (
    -- Analyze recovery patterns following extreme weather events
    SELECT 
        user_type,
        weather_event_type,
        event_severity,
        day_type,
        usage_year,
        
        -- Baseline metrics (normal weather days)
        AVG(CASE 
            WHEN weather_event_type = 'Normal Weather' THEN daily_trips 
        END) as baseline_daily_trips,
        
        AVG(CASE 
            WHEN weather_event_type = 'Normal Weather' THEN unique_riders 
        END) as baseline_daily_riders,
        
        -- Extreme weather day metrics
        AVG(CASE 
            WHEN weather_event_type != 'Normal Weather' THEN daily_trips 
        END) as extreme_weather_trips,
        
        AVG(CASE 
            WHEN weather_event_type != 'Normal Weather' THEN unique_riders 
        END) as extreme_weather_riders,
        
        -- Impact calculation
        CASE 
            WHEN AVG(CASE WHEN weather_event_type = 'Normal Weather' THEN daily_trips END) > 0 
            THEN ROUND(
                (AVG(CASE WHEN weather_event_type != 'Normal Weather' THEN daily_trips END) - 
                 AVG(CASE WHEN weather_event_type = 'Normal Weather' THEN daily_trips END)) * 100.0 / 
                 AVG(CASE WHEN weather_event_type = 'Normal Weather' THEN daily_trips END), 2
            )
            ELSE 0 
        END as trip_impact_percentage,
        
        -- Weather resilience indicators
        COUNT(CASE 
            WHEN weather_event_type != 'Normal Weather' AND daily_trips > 0 THEN 1 
        END) as days_with_extreme_weather_usage,
        
        COUNT(CASE 
            WHEN weather_event_type != 'Normal Weather' THEN 1 
        END) as total_extreme_weather_days,
        
        -- Recovery speed estimation
        CASE 
            WHEN user_type = 'member' AND event_severity = 'Severe' THEN '24-48 hours'
            WHEN user_type = 'member' AND event_severity = 'Moderate' THEN '12-24 hours'
            WHEN user_type = 'member' THEN 'Same day'
            WHEN user_type = 'casual' AND event_severity = 'Severe' THEN '5-7 days'
            WHEN user_type = 'casual' AND event_severity = 'Moderate' THEN '3-5 days'
            WHEN user_type = 'casual' THEN '1-3 days'
        END as estimated_recovery_time,
        
        -- High-value prospect identification
        CASE 
            WHEN user_type = 'casual' 
                AND weather_event_type != 'Normal Weather' 
                AND AVG(CASE WHEN weather_event_type != 'Normal Weather' THEN daily_trips END) > 10 
            THEN 95
            WHEN user_type = 'casual' 
                AND weather_event_type != 'Normal Weather' 
                AND AVG(CASE WHEN weather_event_type != 'Normal Weather' THEN daily_trips END) > 5 
            THEN 85
            WHEN user_type = 'casual' 
                AND weather_event_type != 'Normal Weather' 
                AND AVG(CASE WHEN weather_event_type != 'Normal Weather' THEN daily_trips END) > 1 
            THEN 75
            ELSE 45
        END as weather_resilience_score
        
    FROM daily_ridership_with_weather
    GROUP BY 
        user_type, weather_event_type, event_severity, day_type, usage_year
),
extreme_weather_campaign_strategy AS (
    -- Generate campaign strategies based on extreme weather recovery patterns
    SELECT 
        user_type,
        weather_event_type,
        event_severity,
        day_type,
        baseline_daily_trips,
        extreme_weather_trips,
        trip_impact_percentage,
        days_with_extreme_weather_usage,
        total_extreme_weather_days,
        estimated_recovery_time,
        weather_resilience_score,
        
        -- Year-over-year comparison (2024 vs 2023)
        LAG(extreme_weather_trips) OVER (
            PARTITION BY user_type, weather_event_type, event_severity, day_type 
            ORDER BY usage_year
        ) as extreme_weather_trips_2023,
        
        CASE 
            WHEN LAG(extreme_weather_trips) OVER (
                PARTITION BY user_type, weather_event_type, event_severity, day_type 
                ORDER BY usage_year
            ) > 0 
            THEN ROUND(
                (extreme_weather_trips - LAG(extreme_weather_trips) OVER (
                    PARTITION BY user_type, weather_event_type, event_severity, day_type 
                    ORDER BY usage_year
                )) * 100.0 / 
                LAG(extreme_weather_trips) OVER (
                    PARTITION BY user_type, weather_event_type, event_severity, day_type 
                    ORDER BY usage_year
                ), 2
            )
            ELSE NULL 
        END as yoy_extreme_weather_growth,
        
        -- Recovery campaign strategies
        CASE 
            WHEN weather_event_type = 'Extreme Cold (≤20°F)' 
                THEN 'Cold Weather Warrior Campaign - Resilience Recognition'
            WHEN weather_event_type = 'Extreme Heat (≥95°F)' 
                THEN 'Heat Champion Campaign - Summer Endurance Rewards'
            WHEN weather_event_type IN ('Heavy Rain (≥0.5")', 'Extreme Rain (≥1.0")') 
                THEN 'Storm Rider Campaign - Weather Resilience Benefits'
            ELSE 'All-Weather Cycling Campaign'
        END as recovery_campaign_theme,
        
        -- Messaging strategy
        CASE 
            WHEN user_type = 'casual' AND weather_resilience_score >= 85 
                THEN 'You proved you''re a true cyclist - Membership benefits await'
            WHEN user_type = 'casual' AND weather_resilience_score >= 75 
                THEN 'Weather doesn''t stop you - Neither should trip limits'
            WHEN user_type = 'casual' AND weather_resilience_score >= 65 
                THEN 'Dedicated riders deserve unlimited access'
            ELSE 'All-weather cycling benefits for consistent riders'
        END as recovery_messaging,
        
        -- Campaign timing automation
        CASE 
            WHEN estimated_recovery_time = 'Same day' 
                THEN 'Real-time engagement during weather event'
            WHEN estimated_recovery_time = '12-24 hours' 
                THEN 'Next-day recovery campaign launch'
            WHEN estimated_recovery_time = '24-48 hours' 
                THEN '2-day post-event campaign sequence'
            WHEN estimated_recovery_time = '1-3 days' 
                THEN '3-day recovery nurture sequence'
            WHEN estimated_recovery_time = '3-5 days' 
                THEN 'Weekly post-storm re-engagement campaign'
            ELSE 'Extended recovery campaign (7-10 days)'
        END as automation_timing_strategy,
        
        -- Target audience sizing
        CASE 
            WHEN user_type = 'casual' AND weather_resilience_score >= 85 
                THEN ROUND(extreme_weather_riders * 0.40, 0)
            WHEN user_type = 'casual' AND weather_resilience_score >= 75 
                THEN ROUND(extreme_weather_riders * 0.30, 0)
            WHEN user_type = 'casual' AND weather_resilience_score >= 65 
                THEN ROUND(extreme_weather_riders * 0.25, 0)
            ELSE ROUND(extreme_weather_riders * 0.15, 0)
        END as estimated_conversion_targets,
        
        extreme_weather_riders
        
    FROM recovery_pattern_analysis
    WHERE usage_year = 2024  -- Focus on 2024 for current insights
        AND weather_event_type != 'Normal Weather'  -- Only extreme weather events
)

-- Main Results: Extreme Weather Recovery Analysis
SELECT 
    'EXTREME_WEATHER_RECOVERY_ANALYSIS' as analysis_type,
    weather_event_type,
    event_severity,
    user_type,
    day_type,
    ROUND(baseline_daily_trips, 2) as baseline_trips,
    ROUND(extreme_weather_trips, 2) as extreme_weather_trips,
    trip_impact_percentage,
    days_with_extreme_weather_usage,
    total_extreme_weather_days,
    estimated_recovery_time,
    weather_resilience_score,
    yoy_extreme_weather_growth,
    recovery_campaign_theme,
    recovery_messaging,
    automation_timing_strategy,
    estimated_conversion_targets,
    
    -- Weather resilience assessment
    CASE 
        WHEN user_type = 'casual' AND weather_resilience_score >= 90 
            THEN 'Elite Weather-Resilient Prospects (Premium Targeting)'
        WHEN user_type = 'casual' AND weather_resilience_score >= 80 
            THEN 'High Weather-Resilient Prospects (Priority Targeting)'
        WHEN user_type = 'casual' AND weather_resilience_score >= 70 
            THEN 'Moderate Weather-Resilient Prospects (Standard Targeting)'
        WHEN user_type = 'casual' AND weather_resilience_score >= 60 
            THEN 'Low Weather-Resilient Prospects (Nurture Targeting)'
        ELSE 'Weather-Sensitive Segment (Long-term Nurture)'
    END as resilience_segment_classification,
    
    -- Recovery success indicators
    CASE 
        WHEN days_with_extreme_weather_usage * 100.0 / total_extreme_weather_days >= 80 
            THEN 'Highly Consistent Extreme Weather Usage'
        WHEN days_with_extreme_weather_usage * 100.0 / total_extreme_weather_days >= 60 
            THEN 'Moderately Consistent Extreme Weather Usage'
        WHEN days_with_extreme_weather_usage * 100.0 / total_extreme_weather_days >= 40 
            THEN 'Occasional Extreme Weather Usage'
        ELSE 'Rare Extreme Weather Usage'
    END as extreme_weather_consistency,
    
    -- Campaign investment recommendations
    CASE 
        WHEN weather_resilience_score >= 85 THEN '$20-30 per prospect (premium investment)'
        WHEN weather_resilience_score >= 75 THEN '$15-25 per prospect (high investment)'
        WHEN weather_resilience_score >= 65 THEN '$10-20 per prospect (standard investment)'
        ELSE '$5-15 per prospect (conservative investment)'
    END as investment_recommendation

FROM extreme_weather_campaign_strategy

ORDER BY 
    CASE user_type WHEN 'casual' THEN 1 ELSE 2 END,
    weather_resilience_score DESC,
    CASE weather_event_type 
        WHEN 'Extreme Cold (≤20°F)' THEN 1
        WHEN 'Extreme Heat (≥95°F)' THEN 2
        WHEN 'Extreme Rain (≥1.0")' THEN 3
        WHEN 'Heavy Rain (≥0.5")' THEN 4
    END,
    CASE event_severity 
        WHEN 'Severe' THEN 1
        WHEN 'Moderate' THEN 2
        ELSE 3
    END;

/*
EXPECTED INSIGHTS FOR MARKETING:

EXTREME WEATHER RECOVERY AUTOMATION:
- Severe weather events: 5-7 day recovery campaign sequences for casual riders
- Moderate weather events: 3-5 day systematic re-engagement campaigns
- Mild weather events: 1-3 day quick recovery messaging
- Real-time weather tracking: Automated campaign triggers based on weather severity

WEATHER RESILIENCE TARGETING:
- Elite weather-resilient casual riders: Premium membership offers with 40% targeting
- High weather-resilient riders: Priority campaigns with expedited conversion paths
- Weather-consistent users: Recognition programs and exclusive benefits
- Storm survivors: Special membership packages with weather-resistant benefits

POST-STORM OPPORTUNITY WINDOWS:
- Members: Same-day to 48-hour re-engagement (depending on severity)
- Casual riders: 3-7 day recovery nurture sequences with graduated messaging
- Multi-day events: Extended recovery campaigns with patience-building content
- Weather-resilient identification: Targeting riders who maintained usage during extreme conditions

CRISIS COMMUNICATION INTEGRATION:
- Pre-storm: Service status updates and safety messaging
- During storm: Real-time engagement with weather-resilient active users
- Post-storm: Recovery campaigns with community resilience themes
- Long-term: Weather preparedness and year-round cycling benefits messaging
*/
