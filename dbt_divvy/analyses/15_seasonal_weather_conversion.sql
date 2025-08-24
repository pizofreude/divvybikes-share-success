/*
BUSINESS QUESTION 4C: Seasonal Weather Effects on Conversion Potential

OBJECTIVE: Analyze how seasonal weather patterns affect conversion opportunities:
- Weather-driven seasonal usage patterns by user type
- Optimal weather windows for membership campaigns within each season
- Weather comfort zone analysis for casual rider engagement
- Seasonal weather-based messaging strategy development

MARKETING APPLICATION:
- Season-specific weather-based campaign calendars
- Weather pattern predictions for annual marketing budget allocation
- Comfort zone targeting for casual riders in each season
- Weather resilience messaging for year-round membership benefits

EXPECTED INSIGHTS:
- Spring (March-May): Temperature variability creates conversion windows during warm spells
- Summer (June-August): Heat tolerance segmentation opportunities 
- Fall (September-November): Weather transition period shows membership value
- Winter (December-February): Weather-resilient casual riders are premium conversion targets
*/

WITH seasonal_weather_patterns AS (
    -- Analyze seasonal weather conditions and their impact on ridership
    SELECT 
        EXTRACT(year FROM t.started_at) as usage_year,
        CASE 
            WHEN EXTRACT(month FROM t.started_at) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(month FROM t.started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM t.started_at) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END as season,
        
        DATE(t.started_at) as trip_date,
        
        -- Weather metrics
        w.temperature_2m_mean,
        COALESCE(w.precipitation_sum, 0) as precipitation,
        
        -- Weather comfort categorization using existing categories
        CASE 
            WHEN w.temperature_category IN ('Warm', 'Hot') AND w.precipitation_category != 'Extreme Rain'
                THEN 'Perfect Cycling Weather'
            WHEN w.temperature_category = 'Comfortable' AND w.precipitation_category != 'Extreme Rain'
                THEN 'Good Cycling Weather'
            WHEN w.temperature_category IN ('Cool', 'Mild') AND w.precipitation_category != 'Extreme Rain'
                THEN 'Acceptable Cycling Weather'
            WHEN w.precipitation_category = 'Extreme Rain'
                THEN 'Poor Weather - Rain'
            WHEN w.temperature_category = 'Cold'
                THEN 'Poor Weather - Cold'
            WHEN w.temperature_category = 'Very Hot'
                THEN 'Poor Weather - Hot'
            ELSE 'Marginal Cycling Weather'
        END as weather_comfort_category,
        
        t.member_casual as user_type,
        
        -- Trip metrics
        COUNT(*) as daily_trips,
        COUNT(DISTINCT 
            CASE 
                WHEN t.start_station_name IS NULL OR t.start_station_name = '' THEN 'Unknown Station'
                ELSE t.start_station_name 
            END
        ) as unique_daily_riders,
        
        AVG(t.ride_length_minutes) as avg_trip_duration,
        AVG(t.trip_distance_km) as avg_trip_distance,
        
        -- Quality and purpose metrics
        COUNT(CASE 
            WHEN t.ride_length_minutes BETWEEN 5 AND 45 THEN 1 
        END) as quality_trips,
        
        COUNT(CASE 
            WHEN EXTRACT(hour FROM t.started_at) BETWEEN 7 AND 9 
                OR EXTRACT(hour FROM t.started_at) BETWEEN 17 AND 19 
            THEN 1 
        END) as commute_trips,
        
        COUNT(CASE 
            WHEN EXTRACT(dow FROM t.started_at) IN (0, 6) THEN 1 
        END) as weekend_trips
        
    FROM "divvy"."public_gold"."trips_enhanced" t
    JOIN "divvy"."public_silver"."weather_cleaned" w 
        ON DATE(t.started_at) = DATE(w.weather_date)
    WHERE EXTRACT(year FROM t.started_at) IN (2023, 2024)
        AND t.ride_length_minutes > 0 
        AND t.ride_length_minutes < 1440
        AND w.temperature_2m_mean IS NOT NULL
    GROUP BY 
        EXTRACT(year FROM t.started_at),
        CASE 
            WHEN EXTRACT(month FROM t.started_at) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(month FROM t.started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM t.started_at) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END,
        DATE(t.started_at),
        w.temperature_2m_mean,
        COALESCE(w.precipitation_sum, 0),
        CASE 
            WHEN w.temperature_category IN ('Warm', 'Hot') AND w.precipitation_category != 'Extreme Rain'
                THEN 'Perfect Cycling Weather'
            WHEN w.temperature_category = 'Comfortable' AND w.precipitation_category != 'Extreme Rain'
                THEN 'Good Cycling Weather'
            WHEN w.temperature_category IN ('Cool', 'Mild') AND w.precipitation_category != 'Extreme Rain'
                THEN 'Acceptable Cycling Weather'
            WHEN w.precipitation_category = 'Extreme Rain'
                THEN 'Poor Weather - Rain'
            WHEN w.temperature_category = 'Cold'
                THEN 'Poor Weather - Cold'
            WHEN w.temperature_category = 'Very Hot'
                THEN 'Poor Weather - Hot'
            ELSE 'Marginal Cycling Weather'
        END,
        t.member_casual
),
seasonal_weather_analysis AS (
    -- Aggregate seasonal weather impact analysis
    SELECT 
        season,
        weather_comfort_category,
        user_type,
        usage_year,
        
        -- Core metrics
        COUNT(DISTINCT trip_date) as days_in_category,
        SUM(daily_trips) as total_trips,
        SUM(unique_daily_riders) as total_unique_riders,
        ROUND(AVG(daily_trips), 2) as avg_daily_trips,
        ROUND(AVG(unique_daily_riders), 2) as avg_daily_riders,
        
        -- Weather condition averages
        ROUND(AVG(temperature_2m_mean), 2) as avg_temperature,
        ROUND(AVG(precipitation), 3) as avg_precipitation,
        
        -- Behavioral metrics
        ROUND(AVG(avg_trip_duration), 2) as avg_duration,
        ROUND(AVG(avg_trip_distance), 2) as avg_distance,
        ROUND(SUM(quality_trips) * 100.0 / SUM(daily_trips), 2) as quality_trip_percentage,
        ROUND(SUM(commute_trips) * 100.0 / SUM(daily_trips), 2) as commute_percentage,
        ROUND(SUM(weekend_trips) * 100.0 / SUM(daily_trips), 2) as weekend_percentage,
        
        -- Usage intensity
        ROUND(SUM(daily_trips) * 1.0 / SUM(unique_daily_riders), 2) as trips_per_rider,
        
        -- Conversion opportunity indicators
        CASE 
            WHEN user_type = 'casual' AND weather_comfort_category = 'Perfect Cycling Weather' 
                AND AVG(daily_trips) > 500 THEN 95
            WHEN user_type = 'casual' AND weather_comfort_category = 'Good Cycling Weather' 
                AND AVG(daily_trips) > 300 THEN 85
            WHEN user_type = 'casual' AND weather_comfort_category = 'Acceptable Cycling Weather' 
                AND AVG(daily_trips) > 200 THEN 75
            WHEN user_type = 'casual' AND weather_comfort_category LIKE 'Poor Weather%' 
                AND AVG(daily_trips) > 50 THEN 90  -- Weather-resilient riders
            WHEN user_type = 'casual' THEN 65
            ELSE 45
        END as seasonal_conversion_score
        
    FROM seasonal_weather_patterns
    GROUP BY season, weather_comfort_category, user_type, usage_year
),
seasonal_campaign_opportunities AS (
    -- Identify seasonal campaign opportunities based on weather patterns
    SELECT 
        season,
        weather_comfort_category,
        user_type,
        days_in_category,
        avg_daily_trips,
        avg_daily_riders,
        avg_temperature,
        avg_precipitation,
        trips_per_rider,
        quality_trip_percentage,
        seasonal_conversion_score,
        
        -- Year-over-year comparison (2024 vs 2023)
        LAG(avg_daily_trips) OVER (
            PARTITION BY season, weather_comfort_category, user_type 
            ORDER BY usage_year
        ) as trips_2023,
        
        CASE 
            WHEN LAG(avg_daily_trips) OVER (
                PARTITION BY season, weather_comfort_category, user_type 
                ORDER BY usage_year
            ) > 0 
            THEN ROUND(
                (avg_daily_trips - LAG(avg_daily_trips) OVER (
                    PARTITION BY season, weather_comfort_category, user_type 
                    ORDER BY usage_year
                )) * 100.0 / 
                LAG(avg_daily_trips) OVER (
                    PARTITION BY season, weather_comfort_category, user_type 
                    ORDER BY usage_year
                ), 2
            )
            ELSE NULL 
        END as yoy_growth_percent,
        
        -- Seasonal campaign strategies
        CASE 
            WHEN season = 'Spring' AND weather_comfort_category = 'Perfect Cycling Weather' 
                THEN 'Spring Awakening Campaign - New Season, New Membership'
            WHEN season = 'Spring' AND weather_comfort_category = 'Good Cycling Weather' 
                THEN 'Variable Weather Resilience - Members Ride Through Spring Showers'
            WHEN season = 'Summer' AND weather_comfort_category = 'Perfect Cycling Weather' 
                THEN 'Peak Summer Campaign - Unlimited Access for Peak Season'
            WHEN season = 'Summer' AND weather_comfort_category LIKE 'Poor Weather - Hot' 
                THEN 'Beat the Heat Campaign - Extended Time for Hot Weather'
            WHEN season = 'Fall' AND weather_comfort_category = 'Good Cycling Weather' 
                THEN 'Fall Consistency Campaign - Lock in Membership Before Winter'
            WHEN season = 'Winter' AND weather_comfort_category LIKE 'Poor Weather%' 
                THEN 'Winter Warrior Campaign - Year-Round Cycling Benefits'
            ELSE 'General Seasonal Membership Campaign'
        END as seasonal_campaign_theme,
        
        -- Weather-based messaging
        CASE 
            WHEN weather_comfort_category = 'Perfect Cycling Weather' 
                THEN 'Perfect conditions await - Maximize every ride with membership'
            WHEN weather_comfort_category = 'Good Cycling Weather' 
                THEN 'Good riding weather - Consistent access for consistent riders'
            WHEN weather_comfort_category = 'Acceptable Cycling Weather' 
                THEN 'Dedicated cyclists deserve membership benefits'
            WHEN weather_comfort_category LIKE 'Poor Weather%' 
                THEN 'Weather won''t stop you - Neither should trip limits'
            ELSE 'All-weather cycling - Membership for every condition'
        END as weather_messaging,
        
        -- Campaign timing recommendations
        CASE 
            WHEN seasonal_conversion_score >= 90 THEN 'Priority deployment - immediate launch'
            WHEN seasonal_conversion_score >= 80 THEN 'High priority - 24-48 hour launch'
            WHEN seasonal_conversion_score >= 70 THEN 'Standard priority - weekly planning'
            ELSE 'Low priority - monthly planning'
        END as campaign_priority,
        
        -- Target audience sizing
        CASE 
            WHEN user_type = 'casual' AND seasonal_conversion_score >= 90 
                THEN ROUND(avg_daily_riders * 0.30, 0)
            WHEN user_type = 'casual' AND seasonal_conversion_score >= 80 
                THEN ROUND(avg_daily_riders * 0.25, 0)
            WHEN user_type = 'casual' AND seasonal_conversion_score >= 70 
                THEN ROUND(avg_daily_riders * 0.20, 0)
            ELSE ROUND(avg_daily_riders * 0.15, 0)
        END as estimated_conversion_targets
        
    FROM seasonal_weather_analysis
    WHERE usage_year = 2024  -- Focus on 2024 insights for 2025 planning
),
seasonal_weather_insights AS (
    -- Generate comprehensive seasonal weather insights
    SELECT 
        season,
        weather_comfort_category,
        user_type,
        days_in_category,
        avg_daily_trips,
        avg_daily_riders,
        CONCAT(ROUND(avg_temperature, 0), '°F') as average_temperature,
        CONCAT(ROUND(avg_precipitation * 1000, 1), ' mm') as average_precipitation,
        trips_per_rider,
        quality_trip_percentage,
        seasonal_conversion_score,
        yoy_growth_percent,
        seasonal_campaign_theme,
        weather_messaging,
        campaign_priority,
        estimated_conversion_targets,
        
        -- Weather forecast integration strategy
        CASE 
            WHEN weather_comfort_category = 'Perfect Cycling Weather' 
                THEN 'Integrate 5-7 day weather forecasts for optimal campaign timing'
            WHEN weather_comfort_category = 'Good Cycling Weather' 
                THEN 'Monitor 3-5 day weather patterns for opportunity windows'
            WHEN weather_comfort_category LIKE 'Poor Weather%' 
                THEN 'Use weather alerts for post-storm recovery campaigns'
            ELSE 'Standard seasonal weather trend monitoring'
        END as forecast_integration_strategy,
        
        -- Seasonal weather resilience assessment
        CASE 
            WHEN user_type = 'casual' AND weather_comfort_category LIKE 'Poor Weather%' 
                AND avg_daily_trips > 50 
                THEN 'High-Value Weather-Resilient Segment'
            WHEN user_type = 'casual' AND weather_comfort_category = 'Perfect Cycling Weather' 
                AND avg_daily_trips > 500 
                THEN 'Peak Conditions High-Volume Segment'
            WHEN user_type = 'casual' AND weather_comfort_category = 'Good Cycling Weather' 
                AND avg_daily_trips > 300 
                THEN 'Consistent Good Weather Segment'
            ELSE 'Standard Seasonal Segment'
        END as weather_resilience_segment
        
    FROM seasonal_campaign_opportunities
)

-- Main Results: Seasonal Weather Effects Analysis
SELECT 
    'SEASONAL_WEATHER_EFFECTS_ANALYSIS' as analysis_type,
    season,
    weather_comfort_category,
    user_type,
    days_in_category,
    avg_daily_trips,
    avg_daily_riders,
    average_temperature,
    average_precipitation,
    trips_per_rider,
    quality_trip_percentage,
    seasonal_conversion_score,
    yoy_growth_percent,
    seasonal_campaign_theme,
    weather_messaging,
    campaign_priority,
    estimated_conversion_targets,
    forecast_integration_strategy,
    weather_resilience_segment,
    
    -- Annual planning insights
    CASE 
        WHEN season = 'Spring' THEN 'Variable weather creates short-term opportunity windows'
        WHEN season = 'Summer' THEN 'Consistent usage with heat tolerance segmentation'
        WHEN season = 'Fall' THEN 'Transition period ideal for membership value messaging'
        WHEN season = 'Winter' THEN 'Weather-resilient riders are premium conversion targets'
    END as seasonal_planning_insight

FROM seasonal_weather_insights

ORDER BY 
    CASE season 
        WHEN 'Spring' THEN 1 
        WHEN 'Summer' THEN 2 
        WHEN 'Fall' THEN 3 
        ELSE 4 
    END,
    CASE user_type WHEN 'casual' THEN 1 ELSE 2 END,
    seasonal_conversion_score DESC,
    CASE weather_comfort_category 
        WHEN 'Perfect Cycling Weather' THEN 1
        WHEN 'Good Cycling Weather' THEN 2
        WHEN 'Acceptable Cycling Weather' THEN 3
        ELSE 4
    END;

/*
EXPECTED INSIGHTS FOR MARKETING:

SEASONAL WEATHER STRATEGY:
- Spring: Variable weather creates 3-5 day opportunity windows during warm spells
- Summer: Heat tolerance segmentation - identify riders comfortable with 85°F+ temperatures
- Fall: Weather transition messaging - "Members ride through seasonal changes"
- Winter: Weather-resilient casual riders show 90+ conversion scores

WEATHER FORECAST INTEGRATION:
- Perfect weather days: 5-7 day forecast planning for major campaign launches
- Variable conditions: 3-5 day monitoring for tactical campaign adjustments
- Poor weather recovery: Storm tracking for post-weather re-engagement campaigns
- Seasonal transitions: Long-term weather pattern analysis for annual planning

CONVERSION OPTIMIZATION:
- Weather-resilient casual riders in poor conditions: 30% conversion targeting
- Perfect weather high-volume riders: 25% conversion targeting during optimal days
- Seasonal comfort zone analysis: Temperature and precipitation thresholds by season
- Year-round membership value: Weather consistency messaging for all-season benefits
*/
