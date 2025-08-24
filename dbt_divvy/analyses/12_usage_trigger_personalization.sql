/*
BUSINESS QUESTION 3D: Usage-Based Trigger Points and Personalization

OBJECTIVE: Identify specific usage patterns that indicate optimal conversion moments:
- Behavioral trigger points for personalized outreach
- Usage milestone-based offer timing
- Engagement trajectory analysis for intervention timing
- Real-time conversion opportunity detection

MARKETING APPLICATION:
- Trigger automated email campaigns based on usage patterns
- Personalize app notifications and in-ride messaging
- Time phone calls and personal outreach for maximum impact
- Customize offer types based on individual usage profiles

EXPECTED INSIGHTS:
- Trip Frequency Triggers: 10+ trips/month indicates membership consideration
- Distance Triggers: 5+ miles/month suggests regular utility usage
- Consistency Triggers: 3+ days/week usage indicates habit formation
- Milestone Triggers: Anniversary dates and usage achievements
*/

WITH user_journey_analysis AS (
    -- Track individual casual rider journeys and usage evolution
    SELECT 
        COALESCE(start_station_name, 'Unknown Station') as primary_station,
        DATE_TRUNC('month', started_at) as usage_month,
        
        -- Basic usage metrics
        COUNT(*) as monthly_trips,
        COUNT(DISTINCT DATE(started_at)) as active_days_in_month,
        SUM(ride_length_minutes) as total_minutes_in_month,
        SUM(trip_distance_km) as total_distance_in_month,
        
        -- Usage patterns
        COUNT(DISTINCT start_station_id) as unique_start_stations,
        COUNT(DISTINCT end_station_id) as unique_end_stations,
        COUNT(DISTINCT (start_station_id::VARCHAR || '-' || end_station_id::VARCHAR)) as unique_routes,
        
        -- Temporal consistency indicators
        COUNT(DISTINCT EXTRACT(dow FROM started_at)) as days_of_week_used,
        COUNT(DISTINCT EXTRACT(hour FROM started_at)) as hours_of_day_used,
        
        -- Trip purpose indicators
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 
            THEN 1 ELSE 0 
        END) as morning_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 
            THEN 1 ELSE 0 
        END) as evening_commute_trips,
        
        -- Quality indicators  
        AVG(ride_length_minutes) as avg_trip_duration,
        COUNT(CASE 
            WHEN ride_length_minutes BETWEEN 5 AND 45 THEN 1 
        END) as practical_trips,
        
        -- Progression indicators
        MIN(DATE(started_at)) as first_trip_date,
        MAX(DATE(started_at)) as last_trip_date,
        COUNT(DISTINCT DATE(started_at)) as total_days_active
        
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        COALESCE(start_station_name, 'Unknown Station'),
        DATE_TRUNC('month', started_at)
),
usage_milestone_tracking AS (
    -- Identify key usage milestones and trigger points
    SELECT 
        primary_station,
        usage_month,
        monthly_trips,
        active_days_in_month,
        total_minutes_in_month,
        total_distance_in_month,
        unique_routes,
        days_of_week_used,
        ROUND(avg_trip_duration, 2) as avg_trip_duration,
        morning_commute_trips + evening_commute_trips as commute_trips,
        
        -- Calculated trigger indicators
        ROUND(monthly_trips * 1.0 / active_days_in_month, 2) as trips_per_active_day,
        ROUND(total_distance_in_month, 2) as monthly_distance,
        ROUND(total_minutes_in_month / 60.0, 2) as monthly_hours,
        
        -- Engagement depth scoring
        CASE 
            WHEN active_days_in_month >= 20 THEN 'Daily User'
            WHEN active_days_in_month >= 15 THEN 'Frequent User'  
            WHEN active_days_in_month >= 10 THEN 'Regular User'
            WHEN active_days_in_month >= 5 THEN 'Occasional User'
            ELSE 'Infrequent User'
        END as usage_frequency_category,
        
        -- Consistency indicators
        CASE 
            WHEN days_of_week_used >= 6 THEN 'Highly Consistent'
            WHEN days_of_week_used >= 4 THEN 'Moderately Consistent'
            WHEN days_of_week_used >= 2 THEN 'Somewhat Consistent'
            ELSE 'Inconsistent'
        END as usage_consistency,
        
        -- Purpose clarity
        CASE 
            WHEN (morning_commute_trips + evening_commute_trips) >= monthly_trips * 0.6 
                THEN 'Commute-Focused'
            WHEN unique_routes >= 5 AND total_distance_in_month >= 20 
                THEN 'Exploration-Focused'
            WHEN avg_trip_duration >= 30 
                THEN 'Recreation-Focused'
            ELSE 'Mixed-Purpose'
        END as primary_usage_purpose,
        
        -- Milestone achievement flags
        CASE WHEN monthly_trips >= 20 THEN 1 ELSE 0 END as milestone_20_trips,
        CASE WHEN monthly_trips >= 15 THEN 1 ELSE 0 END as milestone_15_trips,
        CASE WHEN monthly_trips >= 10 THEN 1 ELSE 0 END as milestone_10_trips,
        CASE WHEN total_distance_in_month >= 50 THEN 1 ELSE 0 END as milestone_50_miles,
        CASE WHEN total_distance_in_month >= 25 THEN 1 ELSE 0 END as milestone_25_miles,
        CASE WHEN active_days_in_month >= 15 THEN 1 ELSE 0 END as milestone_15_days,
        CASE WHEN unique_routes >= 10 THEN 1 ELSE 0 END as milestone_10_routes
        
    FROM user_journey_analysis
    WHERE monthly_trips >= 3  -- Focus on users with meaningful engagement
),
trigger_point_analysis AS (
    -- Analyze optimal trigger points for conversion campaigns
    SELECT 
        usage_frequency_category,
        usage_consistency,
        primary_usage_purpose,
        COUNT(*) as user_segment_size,
        
        -- Usage metrics for this segment
        ROUND(AVG(monthly_trips), 2) as avg_monthly_trips,
        ROUND(AVG(monthly_distance), 2) as avg_monthly_distance,
        ROUND(AVG(monthly_hours), 2) as avg_monthly_hours,
        ROUND(AVG(trips_per_active_day), 2) as avg_trips_per_active_day,
        
        -- Milestone achievement rates
        ROUND(AVG(milestone_20_trips) * 100, 2) as pct_achieving_20_trips,
        ROUND(AVG(milestone_15_trips) * 100, 2) as pct_achieving_15_trips,
        ROUND(AVG(milestone_10_trips) * 100, 2) as pct_achieving_10_trips,
        ROUND(AVG(milestone_25_miles) * 100, 2) as pct_achieving_25_miles,
        ROUND(AVG(milestone_15_days) * 100, 2) as pct_achieving_15_days,
        
        -- Conversion readiness scoring
        CASE 
            WHEN AVG(monthly_trips) >= 15 AND AVG(milestone_15_days) >= 0.5 THEN 95
            WHEN AVG(monthly_trips) >= 10 AND AVG(milestone_10_trips) >= 0.7 THEN 85
            WHEN AVG(monthly_distance) >= 25 AND AVG(milestone_25_miles) >= 0.6 THEN 75
            WHEN AVG(trips_per_active_day) >= 2 AND AVG(milestone_15_days) >= 0.4 THEN 65
            ELSE 45
        END as conversion_readiness_score,
        
        -- Optimal trigger timing
        CASE 
            WHEN AVG(monthly_trips) >= 15 THEN 'Immediate (within 1-3 days of milestone)'
            WHEN AVG(monthly_trips) >= 10 THEN 'Short-term (within 1 week of milestone)'
            WHEN AVG(monthly_distance) >= 20 THEN 'Medium-term (within 2 weeks of milestone)'
            ELSE 'Long-term (within 1 month of milestone)'
        END as optimal_trigger_timing,
        
        -- Personalized offer recommendations
        CASE 
            WHEN AVG(monthly_trips) >= 20 AND primary_usage_purpose = 'Commute-Focused' 
                THEN 'Premium Commuter Package - Guaranteed Bike Access'
            WHEN AVG(monthly_trips) >= 15 AND primary_usage_purpose = 'Recreation-Focused' 
                THEN 'Unlimited Weekend Pass + Member Benefits'
            WHEN AVG(monthly_distance) >= 30 
                THEN 'Distance Champion Membership - Extended Time Limits'
            WHEN AVG(milestone_15_days) >= 0.7 
                THEN 'Consistency Reward - Habit Formation Incentive'
            WHEN primary_usage_purpose = 'Exploration-Focused' 
                THEN 'Explorer Membership - System-Wide Access'
            ELSE 'Standard Membership with First Month Free'
        END as personalized_offer_type,
        
        -- Messaging strategy
        CASE 
            WHEN primary_usage_purpose = 'Commute-Focused' 
                THEN 'Time & Cost Savings - Your Daily Commute Optimized'
            WHEN primary_usage_purpose = 'Recreation-Focused' 
                THEN 'Unlimited Fun - No Limits on Your Adventures'
            WHEN primary_usage_purpose = 'Exploration-Focused' 
                THEN 'City Discovery - Unlock Every Neighborhood'
            ELSE 'Smart Transportation - Flexible, Affordable, Reliable'
        END as personalized_messaging_theme
        
    FROM usage_milestone_tracking
    GROUP BY usage_frequency_category, usage_consistency, primary_usage_purpose
),
campaign_automation_rules AS (
    -- Define specific automation rules for trigger-based campaigns
    SELECT 
        usage_frequency_category,
        usage_consistency, 
        primary_usage_purpose,
        user_segment_size,
        avg_monthly_trips,
        avg_monthly_distance,
        conversion_readiness_score,
        optimal_trigger_timing,
        personalized_offer_type,
        personalized_messaging_theme,
        
        -- Campaign automation specifications
        CASE 
            WHEN conversion_readiness_score >= 85 
                THEN 'Real-time trigger: Immediate email + push notification + personalized call'
            WHEN conversion_readiness_score >= 75 
                THEN 'Near real-time: Email within 24 hours + follow-up in 3 days'
            WHEN conversion_readiness_score >= 65 
                THEN 'Scheduled campaign: Weekly email series + monthly phone outreach'
            ELSE 'Batch campaign: Monthly newsletter + quarterly promotional offers'
        END as automation_strategy,
        
        -- Channel prioritization
        CASE 
            WHEN avg_monthly_trips >= 15 THEN 'Email + SMS + In-App + Phone Call'
            WHEN avg_monthly_trips >= 10 THEN 'Email + In-App + Push Notification'
            WHEN avg_monthly_trips >= 5 THEN 'Email + Push Notification'
            ELSE 'Email Only'
        END as communication_channels,
        
        -- Success metrics and KPIs
        CASE 
            WHEN conversion_readiness_score >= 85 THEN '25-40% conversion rate target'
            WHEN conversion_readiness_score >= 75 THEN '20-30% conversion rate target'
            WHEN conversion_readiness_score >= 65 THEN '15-25% conversion rate target'
            ELSE '10-20% conversion rate target'
        END as success_metrics,
        
        -- Investment per lead recommendation
        CASE 
            WHEN conversion_readiness_score >= 85 THEN '$15-25 per conversion attempt'
            WHEN conversion_readiness_score >= 75 THEN '$10-15 per conversion attempt'
            WHEN conversion_readiness_score >= 65 THEN '$5-10 per conversion attempt'
            ELSE '$2-5 per conversion attempt'
        END as investment_per_lead
        
    FROM trigger_point_analysis
    WHERE user_segment_size >= 10  -- Focus on statistically significant segments
)

-- Main Results: Usage-Based Trigger Points and Personalization
SELECT 
    'USAGE_TRIGGER_ANALYSIS' as analysis_type,
    (usage_frequency_category || ' + ' || usage_consistency || ' + ' || primary_usage_purpose) as user_segment_profile,
    user_segment_size,
    avg_monthly_trips,
    avg_monthly_distance,
    conversion_readiness_score,
    optimal_trigger_timing,
    personalized_offer_type,
    personalized_messaging_theme,
    automation_strategy,
    communication_channels,
    success_metrics,
    investment_per_lead,
    
    -- Implementation priority
    CASE 
        WHEN conversion_readiness_score >= 85 AND user_segment_size >= 50 THEN 'Immediate Implementation'
        WHEN conversion_readiness_score >= 75 AND user_segment_size >= 25 THEN 'High Priority Implementation'
        WHEN conversion_readiness_score >= 65 THEN 'Medium Priority Implementation'
        ELSE 'Low Priority Implementation'
    END as implementation_priority,
    
    -- Monthly potential
    ROUND(user_segment_size * 
        CASE 
            WHEN conversion_readiness_score >= 85 THEN 0.30
            WHEN conversion_readiness_score >= 75 THEN 0.25
            WHEN conversion_readiness_score >= 65 THEN 0.20
            ELSE 0.15
        END, 0
    ) as estimated_monthly_conversions

FROM campaign_automation_rules

ORDER BY conversion_readiness_score DESC, user_segment_size DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

USAGE-BASED TRIGGER STRATEGIES:
- High-Frequency Users (15+ trips/month): Immediate conversion campaigns with premium offers
- Consistent Users (15+ days/month): Habit reinforcement messaging and loyalty benefits
- Commute-Focused Users: Time and cost savings emphasis, guaranteed access benefits
- Explorer Users: System-wide access and discovery-focused messaging

AUTOMATION IMPLEMENTATION:
- Real-time triggers: High-value segments with immediate notification systems
- Scheduled campaigns: Medium-value segments with systematic nurturing
- Batch campaigns: Lower-value segments with efficient mass communication

PERSONALIZATION FRAMEWORK:
- Individual usage milestones trigger personalized offers and messaging
- Segment-based automation rules ensure scalable personalization
- Multi-channel approaches for high-value conversion opportunities
- Investment allocation based on conversion probability and segment size
*/
