/*
Business Question 5 Analysis: Geographic Conversion Potential
Query 17: High-Potential Station Conversion Analysis

INSIGHT OBJECTIVE:
Identify stations with high casual usage but low membership ratios, indicating untapped
conversion potential. Focus on stations where casual riders use the service frequently
but haven't converted to membership, representing prime geographic targets for
location-based marketing campaigns.

MARKETING APPLICATION:
- Deploy station-specific advertising and promotional materials
- Target geo-fenced mobile campaigns around high-potential stations
- Partner with local businesses near high-conversion stations for membership offers
- Optimize bike availability and station capacity at conversion hotspots
- Implement on-site conversion campaigns with QR codes and instant signup incentives

FILE PATH: dbt_divvy/analyses/17_high_potential_station_conversion.sql
*/

WITH station_usage_metrics AS (
    -- Calculate comprehensive station usage metrics by user type
    SELECT 
        t.start_station_id,
        t.start_station_id as station_name,  -- Use station_id as name since join fails
        AVG(t.start_lat) as latitude,        -- Use trip coordinates
        AVG(t.start_lng) as longitude,
        
        -- Usage volume analysis
        COUNT(*) as total_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) as casual_trips,
        COUNT(CASE WHEN t.member_casual = 'member' THEN 1 END) as member_trips,
        
        -- Engagement depth metrics
        ROUND(AVG(CASE WHEN t.member_casual = 'casual' THEN t.ride_length_minutes END), 2) as avg_casual_duration,
        ROUND(AVG(CASE WHEN t.member_casual = 'member' THEN t.ride_length_minutes END), 2) as avg_member_duration,
        
        -- Temporal usage patterns
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(dow FROM t.started_at) IN (1,2,3,4,5) THEN 1 END) as casual_weekday_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 7 AND 9 THEN 1 END) as casual_morning_commute,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 17 AND 19 THEN 1 END) as casual_evening_commute,
        
        -- Quality trip indicators
        COUNT(CASE WHEN t.member_casual = 'casual' AND t.ride_length_minutes BETWEEN 5 AND 60 THEN 1 END) as casual_quality_trips,
        
        -- Year-over-year growth analysis
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2024 AND t.member_casual = 'casual' THEN 1 END) as casual_trips_2024,
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2023 AND t.member_casual = 'casual' THEN 1 END) as casual_trips_2023
        
    FROM "divvy"."public_gold"."trips_enhanced" t
    WHERE t.started_at >= '2023-01-01'
        AND t.started_at < '2025-01-01'
        AND t.start_station_id IS NOT NULL
        AND t.start_station_id != ''  -- Exclude empty strings
        AND t.ride_length_minutes > 0
        AND t.start_lat IS NOT NULL
        AND t.start_lng IS NOT NULL
    GROUP BY t.start_station_id
    HAVING COUNT(*) >= 50  -- Focus on stations with meaningful usage
),
conversion_potential_analysis AS (
    -- Calculate conversion potential metrics and scoring
    SELECT 
        *,
        
        -- Core conversion metrics
        ROUND((casual_trips * 100.0 / NULLIF(total_trips, 0)), 2) as casual_usage_percentage,
        ROUND((member_trips * 100.0 / NULLIF(total_trips, 0)), 2) as member_usage_percentage,
        
        -- Engagement quality indicators
        ROUND((casual_quality_trips * 100.0 / NULLIF(casual_trips, 0)), 2) as casual_quality_percentage,
        ROUND((casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0)), 2) as casual_weekday_percentage,
        ROUND(((casual_morning_commute + casual_evening_commute) * 100.0 / NULLIF(casual_trips, 0)), 2) as casual_commuter_percentage,
        
        -- Year-over-year growth calculation
        CASE 
            WHEN casual_trips_2023 > 0 THEN 
                ROUND(((casual_trips_2024 - casual_trips_2023) * 100.0 / casual_trips_2023), 2)
            ELSE NULL
        END as yoy_casual_growth_percent
        
    FROM station_usage_metrics
)
SELECT 
    'HIGH_POTENTIAL_STATION_ANALYSIS' as analysis_type,
    start_station_id,
    station_name,
    latitude,
    longitude,
    total_trips,
    casual_trips,
    member_trips,
    casual_usage_percentage,
    member_usage_percentage,
    casual_quality_percentage,
    casual_weekday_percentage,
    casual_commuter_percentage,
    avg_casual_duration,
    avg_member_duration,
    yoy_casual_growth_percent,
    
    -- Conversion opportunity scoring (0-100 scale)
    CASE 
        WHEN casual_usage_percentage >= 75 AND casual_commuter_percentage >= 20 
            THEN 95  -- Highest conversion potential
        WHEN casual_usage_percentage >= 65 AND casual_quality_percentage >= 75 
            THEN 85  -- High conversion potential
        WHEN casual_usage_percentage >= 55 AND casual_weekday_percentage >= 60 
            THEN 75  -- Good conversion potential
        WHEN casual_usage_percentage >= 45 AND casual_quality_percentage >= 65 
            THEN 65  -- Moderate conversion potential
        WHEN casual_usage_percentage >= 30 
            THEN 45  -- Lower conversion potential
        ELSE 25  -- Limited conversion potential
    END as conversion_opportunity_score,
    
    -- Geographic campaign strategy recommendations
    CASE 
        WHEN casual_commuter_percentage >= 25 
            THEN 'Commuter Conversion Campaign - Rush hour targeting with time-saving benefits'
        WHEN casual_weekday_percentage >= 70 
            THEN 'Business District Campaign - Professional membership packages'
        WHEN casual_quality_percentage >= 80 
            THEN 'Regular User Campaign - Highlight cost savings and convenience'
        ELSE 'General Awareness Campaign - Basic membership introduction'
    END as recommended_campaign_strategy,
    
    -- Target audience profiling
    CASE 
        WHEN casual_commuter_percentage >= 20 AND casual_weekday_percentage >= 65 
            THEN 'Potential Commuters - High Value Prospects'
        WHEN casual_quality_percentage >= 75 
            THEN 'Regular Recreational Users - Consistent Engagement'
        WHEN casual_usage_percentage >= 70 
            THEN 'Community Hub Users - Local Engagement'
        WHEN yoy_casual_growth_percent >= 50 
            THEN 'Growing User Base - Expansion Opportunity'
        ELSE 'Standard Casual Users - General Targeting'
    END as target_audience_profile,
    
    -- Investment priority classification
    CASE 
        WHEN casual_trips >= 1000 AND casual_usage_percentage >= 65 
            THEN 'Priority Investment - High Volume High Potential'
        WHEN casual_usage_percentage >= 75 
            THEN 'Priority Investment - Premium Conversion Opportunity'
        WHEN casual_trips >= 500 AND casual_usage_percentage >= 55 
            THEN 'Standard Investment - Good Volume Moderate Potential'
        ELSE 'Monitor - Limited Investment Priority'
    END as investment_priority_level,
    
    -- Campaign deployment timeline
    CASE 
        WHEN casual_usage_percentage >= 75 
            THEN 'Immediate deployment - High priority launch'
        WHEN casual_usage_percentage >= 65 
            THEN 'Quick deployment (1-2 weeks) - Priority targeting'
        WHEN casual_usage_percentage >= 55 
            THEN 'Standard deployment (2-4 weeks) - Regular campaign'
        ELSE 'Planned deployment (1-2 months) - Lower priority'
    END as campaign_timing_recommendation
    
FROM conversion_potential_analysis
WHERE casual_usage_percentage >= 20  -- Focus on stations with meaningful conversion potential
ORDER BY casual_usage_percentage DESC, casual_trips DESC
LIMIT 50;
