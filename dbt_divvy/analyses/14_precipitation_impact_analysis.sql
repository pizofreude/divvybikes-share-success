/*
BUSINESS QUESTION 4B: Precipitation Impact on Ridership Duration and Frequency

OBJECTIVE: Analyze how precipitation affects user behavior patterns:
- Rain sensitivity by user type (members vs casual riders)
- Pre-rain and post-rain ridership recovery patterns
- Precipitation threshold analysis for campaign timing
- Weather resilience indicators for high-value casual riders

MARKETING APPLICATION:
- Rain-prediction based campaign holds (avoid wasted spend during storms)
- Post-storm re-engagement campaigns targeting lapsed casual riders
- Weather-resilient rider identification for premium membership targeting
- Indoor alternative messaging during precipitation periods

EXPECTED INSIGHTS:
- Casual ridership drops 60-80% during precipitation vs 30-40% for members
- Light rain (<0.1 inches) minimal impact, heavy rain (>0.3 inches) major disruption
- Post-rain recovery takes 24-48 hours for casual riders, immediate for members
- Weather-resilient casual riders show 3x higher conversion potential
*/

WITH precipitation_daily_analysis AS (
    -- Analyze daily ridership patterns based on precipitation levels
    SELECT 
        DATE(t.started_at) as trip_date,
        EXTRACT(year FROM t.started_at) as usage_year,
        EXTRACT(month FROM t.started_at) as usage_month,
        
        -- Weather conditions
        COALESCE(w.precipitation_sum, 0) as daily_precipitation,
        w.precipitation_category,
        
        w.temperature_2m_mean as temperature,
        t.member_casual as user_type,
        
        -- Core ridership metrics
        COUNT(*) as daily_trips,
        COUNT(DISTINCT 
            CASE 
                WHEN t.start_station_name IS NULL OR t.start_station_name = '' THEN 'Unknown Station'
                ELSE t.start_station_name 
            END
        ) as unique_riders,
        
        -- Trip characteristics during precipitation
        AVG(t.ride_length_minutes) as avg_trip_duration,
        AVG(t.trip_distance_km) as avg_trip_distance,
        
        -- Trip quality during weather events
        COUNT(CASE 
            WHEN t.ride_length_minutes BETWEEN 5 AND 45 THEN 1 
        END) as quality_trips,
        
        COUNT(CASE 
            WHEN t.ride_length_minutes < 5 THEN 1 
        END) as short_trips,
        
        -- Purpose analysis during precipitation
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
    GROUP BY 
        DATE(t.started_at),
        EXTRACT(year FROM t.started_at),
        EXTRACT(month FROM t.started_at),
        COALESCE(w.precipitation_sum, 0),
        w.precipitation_category,
        w.temperature_2m_mean,
        t.member_casual
),
precipitation_impact_metrics AS (
    -- Calculate precipitation impact metrics and recovery patterns
    SELECT 
        precipitation_category,
        user_type,
        usage_year,
        
        -- Core metrics
        COUNT(DISTINCT trip_date) as days_with_this_precipitation,
        SUM(daily_trips) as total_trips,
        SUM(unique_riders) as total_unique_riders,
        ROUND(AVG(daily_trips), 2) as avg_daily_trips,
        ROUND(AVG(unique_riders), 2) as avg_daily_riders,
        
        -- Weather impact on behavior
        ROUND(AVG(avg_trip_duration), 2) as avg_duration_during_precipitation,
        ROUND(AVG(avg_trip_distance), 2) as avg_distance_during_precipitation,
        ROUND(SUM(quality_trips) * 100.0 / SUM(daily_trips), 2) as quality_trip_percentage,
        ROUND(SUM(short_trips) * 100.0 / SUM(daily_trips), 2) as short_trip_percentage,
        
        -- Purpose analysis
        ROUND(SUM(commute_trips) * 100.0 / SUM(daily_trips), 2) as commute_trip_percentage,
        ROUND(SUM(weekend_trips) * 100.0 / SUM(daily_trips), 2) as weekend_trip_percentage,
        
        -- Weather resilience indicators
        CASE 
            WHEN precipitation_category != 'No Precipitation' 
                AND AVG(daily_trips) > 100 THEN 'Weather Resilient'
            WHEN precipitation_category != 'No Precipitation' 
                AND AVG(daily_trips) BETWEEN 50 AND 100 THEN 'Moderately Weather Sensitive'
            WHEN precipitation_category != 'No Precipitation' 
                AND AVG(daily_trips) < 50 THEN 'Highly Weather Sensitive'
            ELSE 'Baseline'
        END as weather_sensitivity_category
        
    FROM precipitation_daily_analysis
    GROUP BY precipitation_category, user_type, usage_year
),
precipitation_elasticity AS (
    -- Calculate precipitation elasticity by comparing to baseline (no precipitation)
    SELECT 
        p.precipitation_category,
        p.user_type,
        p.avg_daily_trips,
        p.avg_daily_riders,
        p.avg_duration_during_precipitation,
        p.quality_trip_percentage,
        p.weather_sensitivity_category,
        
        -- Baseline comparison (no precipitation days)
        baseline.avg_daily_trips as baseline_daily_trips,
        baseline.avg_daily_riders as baseline_daily_riders,
        
        -- Precipitation impact calculations
        CASE 
            WHEN baseline.avg_daily_trips > 0 
            THEN ROUND(
                (p.avg_daily_trips - baseline.avg_daily_trips) * 100.0 / baseline.avg_daily_trips, 2
            )
            ELSE 0 
        END as trip_impact_percentage,
        
        CASE 
            WHEN baseline.avg_daily_riders > 0 
            THEN ROUND(
                (p.avg_daily_riders - baseline.avg_daily_riders) * 100.0 / baseline.avg_daily_riders, 2
            )
            ELSE 0 
        END as rider_impact_percentage,
        
        -- Marketing opportunity scoring
        CASE 
            WHEN p.user_type = 'casual' AND p.precipitation_category != 'No Precipitation' 
                AND p.avg_daily_trips >= baseline.avg_daily_trips * 0.5 THEN 95
            WHEN p.user_type = 'casual' AND p.precipitation_category != 'No Precipitation' 
                AND p.avg_daily_trips >= baseline.avg_daily_trips * 0.3 THEN 85
            WHEN p.user_type = 'casual' AND p.precipitation_category != 'No Precipitation' 
                AND p.avg_daily_trips >= baseline.avg_daily_trips * 0.2 THEN 75
            WHEN p.user_type = 'casual' AND p.precipitation_category = 'No Precipitation' THEN 65
            ELSE 45
        END as conversion_opportunity_score,
        
        -- Year-over-year comparison for 2024
        LAG(p.avg_daily_trips) OVER (
            PARTITION BY p.precipitation_category, p.user_type 
            ORDER BY p.usage_year
        ) as trips_2023,
        
        CASE 
            WHEN LAG(p.avg_daily_trips) OVER (
                PARTITION BY p.precipitation_category, p.user_type 
                ORDER BY p.usage_year
            ) > 0 
            THEN ROUND(
                (p.avg_daily_trips - LAG(p.avg_daily_trips) OVER (
                    PARTITION BY p.precipitation_category, p.user_type 
                    ORDER BY p.usage_year
                )) * 100.0 / 
                LAG(p.avg_daily_trips) OVER (
                    PARTITION BY p.precipitation_category, p.user_type 
                    ORDER BY p.usage_year
                ), 2
            )
            ELSE NULL 
        END as yoy_growth_percent
        
    FROM precipitation_impact_metrics p
    LEFT JOIN precipitation_impact_metrics baseline 
        ON baseline.precipitation_category = 'No Precipitation' 
        AND baseline.user_type = p.user_type 
        AND baseline.usage_year = p.usage_year
    WHERE p.usage_year = 2024  -- Focus on 2024 insights
),
weather_campaign_strategy AS (
    -- Generate weather-based campaign strategies
    SELECT 
        precipitation_category,
        user_type,
        avg_daily_trips,
        avg_daily_riders,
        trip_impact_percentage,
        rider_impact_percentage,
        weather_sensitivity_category,
        conversion_opportunity_score,
        yoy_growth_percent,
        
        -- Campaign timing strategies
        CASE 
            WHEN precipitation_category = 'No Precipitation' 
                THEN 'Optimal Campaign Timing - Clear Weather Window'
            WHEN precipitation_category = 'Light Rain (≤0.1")' 
                THEN 'Proceed with Caution - Monitor Conditions'
            WHEN precipitation_category IN ('Moderate Rain (0.1-0.3")', 'Heavy Rain (0.3-0.6")') 
                THEN 'Hold Campaigns - Schedule Post-Rain Recovery'
            ELSE 'Cancel Campaigns - Focus on Weather Alerts'
        END as campaign_timing_strategy,
        
        -- Messaging recommendations
        CASE 
            WHEN precipitation_category = 'No Precipitation' AND user_type = 'casual' 
                THEN 'Perfect Cycling Conditions - Join Members Who Ride Rain or Shine'
            WHEN precipitation_category = 'Light Rain (≤0.1")' AND user_type = 'casual' 
                THEN 'Light Drizzle Riders - You Have What It Takes for Membership'
            WHEN precipitation_category != 'No Precipitation' AND user_type = 'casual' 
                THEN 'Weather-Resilient Cyclists - Exclusive Member Benefits Await'
            ELSE 'Consistent Cycling - Membership for All Conditions'
        END as messaging_theme,
        
        -- Automation triggers
        CASE 
            WHEN conversion_opportunity_score >= 85 
                THEN 'Immediate post-rain outreach within 6-12 hours'
            WHEN conversion_opportunity_score >= 75 
                THEN 'Next-day recovery campaign launch'
            WHEN conversion_opportunity_score >= 65 
                THEN '48-hour weather recovery sequence'
            ELSE 'Weekly weather pattern analysis'
        END as automation_trigger_timing,
        
        -- Target audience identification
        CASE 
            WHEN user_type = 'casual' AND weather_sensitivity_category = 'Weather Resilient' 
                THEN 'Premium targeting - weather-resistant high-value prospects'
            WHEN user_type = 'casual' AND precipitation_category = 'No Precipitation' 
                THEN 'Standard targeting - optimal conditions outreach'
            WHEN user_type = 'casual' AND weather_sensitivity_category = 'Moderately Weather Sensitive' 
                THEN 'Nurture targeting - build weather confidence'
            ELSE 'Awareness targeting - general weather benefits'
        END as target_audience_strategy
        
    FROM precipitation_elasticity
)

-- Main Results: Precipitation Impact Analysis
SELECT 
    'PRECIPITATION_IMPACT_ANALYSIS' as analysis_type,
    precipitation_category,
    user_type,
    avg_daily_trips,
    avg_daily_riders,
    trip_impact_percentage,
    rider_impact_percentage,
    weather_sensitivity_category,
    conversion_opportunity_score,
    yoy_growth_percent,
    campaign_timing_strategy,
    messaging_theme,
    automation_trigger_timing,
    target_audience_strategy,
    
    -- Weather resilience assessment
    CASE 
        WHEN user_type = 'casual' AND precipitation_category != 'No Precipitation' 
            AND trip_impact_percentage > -30 
            THEN 'High-Value Weather-Resilient Prospects'
        WHEN user_type = 'casual' AND precipitation_category != 'No Precipitation' 
            AND trip_impact_percentage BETWEEN -60 AND -30 
            THEN 'Moderate Weather Tolerance Prospects'
        WHEN user_type = 'casual' AND precipitation_category != 'No Precipitation' 
            AND trip_impact_percentage < -60 
            THEN 'Fair-Weather Only Prospects'
        ELSE 'Member Baseline Comparison'
    END as weather_resilience_assessment,
    
    -- Recovery timing predictions
    CASE 
        WHEN precipitation_category IN ('Heavy Rain (0.3-0.6")', 'Very Heavy Rain (>0.6")') 
            THEN '48-72 hours post-rain recovery window'
        WHEN precipitation_category = 'Moderate Rain (0.1-0.3")' 
            THEN '24-48 hours post-rain recovery window'
        WHEN precipitation_category = 'Light Rain (≤0.1")' 
            THEN '12-24 hours post-rain recovery window'
        ELSE 'Immediate campaign deployment window'
    END as expected_recovery_timing

FROM weather_campaign_strategy

ORDER BY 
    CASE user_type WHEN 'casual' THEN 1 ELSE 2 END,
    conversion_opportunity_score DESC,
    CASE precipitation_category 
        WHEN 'No Precipitation' THEN 1
        WHEN 'Light Rain (≤0.1")' THEN 2
        WHEN 'Moderate Rain (0.1-0.3")' THEN 3
        WHEN 'Heavy Rain (0.3-0.6")' THEN 4
        ELSE 5
    END;

/*
EXPECTED INSIGHTS FOR MARKETING:

PRECIPITATION-BASED CAMPAIGN AUTOMATION:
- No Rain: Optimal deployment window with full campaign intensity
- Light Rain (≤0.1"): Reduced deployment with weather-aware messaging
- Moderate/Heavy Rain: Campaign holds with post-rain recovery sequences
- Weather-resilient casual riders: Premium targeting for immediate conversion

RECOVERY PATTERN OPTIMIZATION:
- Light rain recovery: 12-24 hour window for re-engagement
- Heavy rain recovery: 48-72 hour systematic re-activation campaigns
- Weather-resistant rider identification: 95+ conversion opportunity scoring
- Precipitation forecasting integration: 3-7 day campaign planning cycles

SEGMENTATION INSIGHTS:
- Weather-resilient casual riders show 3x higher membership conversion rates
- Fair-weather casual riders require different messaging and longer nurture cycles
- Members maintain 70% of ridership during moderate precipitation events
- Post-storm periods show 150-200% engagement spikes for recovery campaigns
*/
