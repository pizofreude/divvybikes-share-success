/*
BUSINESS QUESTION 3B: Daily and Hourly Targeting Optimization

OBJECTIVE: Identify optimal day-of-week and time-of-day windows for targeting casual riders:
- Peak engagement times for maximum campaign visibility
- Optimal messaging windows based on usage context (commute vs leisure)
- Day-of-week conversion readiness patterns
- Real-time targeting triggers for mobile/digital campaigns

MARKETING APPLICATION:
- Schedule email campaigns for maximum open rates
- Time social media posts and digital ads for peak engagement
- Trigger push notifications during high-propensity moments
- Optimize customer service availability for conversion support

EXPECTED INSIGHTS:
- Weekday commute hours: 7-9 AM, 5-7 PM - commuter benefit messaging
- Weekend leisure hours: 10 AM-4 PM - recreational value propositions
- Late evening: 8-10 PM - planning and reflection time for membership decisions
- Friday planning: 4-6 PM - weekend preparation and membership consideration
*/

WITH hourly_usage_patterns AS (
    -- Analyze usage patterns by hour and day of week for 2024
    SELECT 
        EXTRACT(dow FROM started_at) as day_of_week,
        CASE EXTRACT(dow FROM started_at)
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday' 
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END as day_name,
        EXTRACT(hour FROM started_at) as hour_of_day,
        
        -- Trip context classification
        CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 THEN 'Weekday Morning Commute'
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 THEN 'Weekday Evening Commute'
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 12 AND 14 THEN 'Weekday Lunch'
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) 
                AND EXTRACT(hour FROM started_at) BETWEEN 10 AND 16 THEN 'Weekend Leisure'
            WHEN EXTRACT(hour FROM started_at) BETWEEN 6 AND 8 THEN 'Early Morning'
            WHEN EXTRACT(hour FROM started_at) BETWEEN 20 AND 22 THEN 'Evening Wind-down'
            ELSE 'Off-Peak'
        END as usage_context,
        
        -- Usage metrics
        COUNT(*) as trip_count,
        COUNT(DISTINCT 
            CASE 
                WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
                ELSE start_station_name 
            END
        ) as unique_riders,
        
        -- Engagement quality indicators
        AVG(ride_length_minutes) as avg_duration,
        COUNT(DISTINCT start_station_id) as stations_used,
        
        -- Repeat usage indicators (engagement depth) - simplified
        ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT 
            CASE 
                WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
                ELSE start_station_name 
            END
        ), 2) as avg_trips_per_rider_slot,
        
        -- Conversion readiness signals
        COUNT(CASE 
            WHEN ride_length_minutes BETWEEN 10 AND 30 THEN 1  -- Optimal duration range
        END) as optimal_duration_trips,
        
        COUNT(CASE 
            WHEN trip_distance_km BETWEEN 1 AND 5 THEN 1  -- Practical distance range
        END) as practical_distance_trips
        
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        EXTRACT(dow FROM started_at),
        CASE EXTRACT(dow FROM started_at)
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday' 
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END,
        EXTRACT(hour FROM started_at),
        CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 THEN 'Weekday Morning Commute'
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 THEN 'Weekday Evening Commute'
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 12 AND 14 THEN 'Weekday Lunch'
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) 
                AND EXTRACT(hour FROM started_at) BETWEEN 10 AND 16 THEN 'Weekend Leisure'
            WHEN EXTRACT(hour FROM started_at) BETWEEN 6 AND 8 THEN 'Early Morning'
            WHEN EXTRACT(hour FROM started_at) BETWEEN 20 AND 22 THEN 'Evening Wind-down'
            ELSE 'Off-Peak'
        END
),
engagement_scoring AS (
    -- Calculate engagement and conversion readiness scores
    SELECT 
        day_name,
        hour_of_day,
        usage_context,
        trip_count,
        unique_riders,
        ROUND(avg_duration, 2) as avg_duration,
        ROUND(avg_trips_per_rider_slot, 2) as avg_trips_per_rider_slot,
        
        -- Engagement quality score (0-100)
        LEAST(100, 
            (optimal_duration_trips * 100.0 / NULLIF(trip_count, 0)) * 0.4 +  -- 40% weight on optimal duration
            (practical_distance_trips * 100.0 / NULLIF(trip_count, 0)) * 0.3 + -- 30% weight on practical distance
            (LEAST(stations_used, 50) * 2) * 0.3  -- 30% weight on station diversity
        ) as engagement_quality_score,
        
        -- Targeting opportunity score
        CASE 
            WHEN trip_count >= 1000 AND unique_riders >= 500 THEN 95
            WHEN trip_count >= 500 AND unique_riders >= 250 THEN 85
            WHEN trip_count >= 250 AND unique_riders >= 100 THEN 75
            WHEN trip_count >= 100 AND unique_riders >= 50 THEN 65
            ELSE 45
        END as targeting_opportunity_score,
        
        -- Message timing effectiveness
        CASE 
            WHEN usage_context IN ('Weekday Morning Commute', 'Weekday Evening Commute') THEN 'High'
            WHEN usage_context IN ('Weekend Leisure', 'Weekday Lunch') THEN 'Medium-High'
            WHEN usage_context IN ('Evening Wind-down') THEN 'Medium'
            ELSE 'Low'
        END as message_timing_effectiveness
        
    FROM hourly_usage_patterns
),
optimal_targeting_windows AS (
    -- Identify optimal targeting windows with campaign recommendations
    SELECT 
        day_name,
        hour_of_day,
        (day_name || ' at ' || hour_of_day || ':00') as targeting_window,
        usage_context,
        trip_count,
        unique_riders,
        avg_duration,
        ROUND(engagement_quality_score, 2) as engagement_quality_score,
        targeting_opportunity_score,
        message_timing_effectiveness,
        
        -- Campaign type recommendations based on context
        CASE 
            WHEN usage_context = 'Weekday Morning Commute' THEN 'Commuter Benefits - Time & Cost Savings'
            WHEN usage_context = 'Weekday Evening Commute' THEN 'Daily Commute Optimization - Stress-Free Travel'
            WHEN usage_context = 'Weekend Leisure' THEN 'Recreation Enhancement - Unlimited Weekend Access'
            WHEN usage_context = 'Weekday Lunch' THEN 'Midday Convenience - Quick & Healthy Breaks'
            WHEN usage_context = 'Evening Wind-down' THEN 'Planning Ahead - Tomorrow Starts Tonight'
            WHEN usage_context = 'Early Morning' THEN 'Early Bird Benefits - Beat the Rush'
            ELSE 'General Membership Value'
        END as recommended_message_theme,
        
        -- Digital channel recommendations
        CASE 
            WHEN targeting_opportunity_score >= 85 AND message_timing_effectiveness = 'High' 
                THEN 'Push Notifications + Email + Social Media'
            WHEN targeting_opportunity_score >= 75 
                THEN 'Email + Social Media + Display Ads'
            WHEN targeting_opportunity_score >= 65 
                THEN 'Social Media + Display Ads'
            ELSE 'Display Ads Only'
        END as recommended_channels,
        
        -- Campaign intensity recommendations
        CASE 
            WHEN targeting_opportunity_score >= 85 THEN 'High Intensity (Daily campaigns)'
            WHEN targeting_opportunity_score >= 75 THEN 'Medium Intensity (3x/week campaigns)'
            WHEN targeting_opportunity_score >= 65 THEN 'Low Intensity (Weekly campaigns)'
            ELSE 'Minimal (Monthly or event-based)'
        END as campaign_intensity,
        
        -- Conversion window prediction
        CASE 
            WHEN usage_context IN ('Weekday Morning Commute', 'Weekday Evening Commute') 
                AND engagement_quality_score > 60 THEN '15-30 minutes (immediate decision window)'
            WHEN usage_context = 'Weekend Leisure' AND engagement_quality_score > 50 
                THEN '1-4 hours (leisure decision window)'
            WHEN usage_context = 'Evening Wind-down' 
                THEN '12-24 hours (overnight consideration)'
            ELSE '24-72 hours (extended consideration)'
        END as expected_conversion_window
        
    FROM engagement_scoring
    WHERE trip_count >= 50  -- Focus on statistically significant windows
)

-- Main Results: Daily and Hourly Targeting Optimization
SELECT 
    'OPTIMAL_TARGETING_WINDOWS' as analysis_type,
    targeting_window,
    usage_context,
    trip_count,
    unique_riders,
    avg_duration,
    engagement_quality_score,
    targeting_opportunity_score,
    message_timing_effectiveness,
    recommended_message_theme,
    recommended_channels,
    campaign_intensity,
    expected_conversion_window,
    
    -- ROI prediction
    CASE 
        WHEN targeting_opportunity_score >= 85 AND engagement_quality_score >= 70 THEN 'Very High ROI Expected'
        WHEN targeting_opportunity_score >= 75 AND engagement_quality_score >= 60 THEN 'High ROI Expected'
        WHEN targeting_opportunity_score >= 65 AND engagement_quality_score >= 50 THEN 'Medium ROI Expected'
        ELSE 'Low ROI Expected'
    END as expected_roi_category

FROM optimal_targeting_windows

ORDER BY targeting_opportunity_score DESC, engagement_quality_score DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

OPTIMAL DAILY TARGETING:
- Monday-Friday 7-9 AM: Commuter messaging, high-intensity campaigns
- Monday-Friday 5-7 PM: Cost savings focus, immediate conversion windows
- Saturday-Sunday 10 AM-4 PM: Recreation value, leisure decision timing
- Friday 4-6 PM: Weekend planning, membership preparation messaging

HOURLY OPTIMIZATION:
- Peak Engagement: 8 AM, 5 PM, 12 PM - maximum visibility windows
- Conversion Windows: 6-8 PM - decision-making and planning time
- Channel Strategy: Multi-channel during high-opportunity windows

CAMPAIGN TIMING STRATEGY:
- Real-time triggers: High engagement moments for push notifications
- Scheduled campaigns: Predictable patterns for email/social media
- Conversion support: Customer service availability during peak decision times
*/
