-- Business Question 5: Geographic Conversion Potential - Route Analysis
-- File: 18_route_commuter_potential_analysis.sql
-- Purpose: Analyze route patterns to identify commuter potential and round-trip behavior

WITH route_base_metrics AS (
    -- Calculate core route metrics and patterns
    SELECT 
        CAST(t.start_station_id AS VARCHAR) || '-' || CAST(t.end_station_id AS VARCHAR) as route_id,
        t.start_station_id,
        t.end_station_id,
        t.start_station_id as start_station_name,
        t.end_station_id as end_station_name,
        
        -- Distance calculation using average coordinates
        ROUND(
            (3959 * ACOS(
                COS(RADIANS(AVG(t.start_lat))) * COS(RADIANS(AVG(t.end_lat))) * 
                COS(RADIANS(AVG(t.end_lng)) - RADIANS(AVG(t.start_lng))) + 
                SIN(RADIANS(AVG(t.start_lat))) * SIN(RADIANS(AVG(t.end_lat)))
            )), 2
        ) as route_distance_miles,
        
        -- Trip volume metrics
        COUNT(*) as total_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) as casual_trips,
        COUNT(CASE WHEN t.member_casual = 'member' THEN 1 END) as member_trips,
        
        -- Temporal patterns for commuter identification
        COUNT(CASE 
            WHEN t.member_casual = 'casual' 
                AND EXTRACT(DOW FROM t.started_at) BETWEEN 1 AND 5 
            THEN 1 
        END) as casual_weekday_trips,
        
        COUNT(CASE 
            WHEN t.member_casual = 'casual' 
                AND EXTRACT(HOUR FROM t.started_at) BETWEEN 7 AND 9 
            THEN 1 
        END) as casual_morning_rush,
        
        COUNT(CASE 
            WHEN t.member_casual = 'casual' 
                AND EXTRACT(HOUR FROM t.started_at) BETWEEN 17 AND 19 
            THEN 1 
        END) as casual_evening_rush
        
    FROM "divvy"."public_gold"."trips_enhanced" t
    WHERE t.started_at >= '2023-01-01'
        AND t.started_at < '2025-01-01'
        AND t.start_station_id IS NOT NULL
        AND t.end_station_id IS NOT NULL
        AND t.start_station_id != t.end_station_id
        AND t.start_station_id != ''
        AND t.end_station_id != ''
        AND t.ride_length_minutes BETWEEN 2 AND 120
        AND t.start_lat IS NOT NULL
        AND t.end_lat IS NOT NULL
    GROUP BY 
        CAST(t.start_station_id AS VARCHAR) || '-' || CAST(t.end_station_id AS VARCHAR),
        t.start_station_id, t.end_station_id
    HAVING COUNT(*) >= 20
        AND COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) >= 5
)

SELECT 
    route_id,
    start_station_name,
    end_station_name,
    route_distance_miles,
    total_trips,
    casual_trips,
    member_trips,
    ROUND((casual_trips * 100.0 / NULLIF(total_trips, 0)), 2) as casual_percentage,
    casual_weekday_trips,
    ROUND((casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0)), 2) as casual_weekday_percentage,
    casual_morning_rush,
    casual_evening_rush,
    ROUND(((casual_morning_rush + casual_evening_rush) * 100.0 / NULLIF(casual_trips, 0)), 2) as casual_rush_hour_percentage,
    
    -- Commuter potential scoring
    ROUND(
        (
            (LEAST(casual_trips / 100.0, 1.0) * 40) +
            ((casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0)) / 100.0 * 35) +
            (((casual_morning_rush + casual_evening_rush) * 100.0 / NULLIF(casual_trips, 0)) / 100.0 * 25)
        ), 2
    ) as commuter_potential_score,
    
    -- Route classification
    CASE 
        WHEN casual_trips >= 50 AND casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0) > 70 
        THEN 'High Commuter Potential'
        WHEN casual_trips >= 30 AND (casual_morning_rush + casual_evening_rush) * 100.0 / NULLIF(casual_trips, 0) > 40 
        THEN 'Rush Hour Focused'
        WHEN casual_trips * 100.0 / NULLIF(total_trips, 0) > 70 
        THEN 'Recreation Route'
        ELSE 'Mixed Usage'
    END as route_type,
    
    -- Campaign strategy
    CASE 
        WHEN casual_trips >= 50 AND casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0) > 75 
        THEN 'Priority Target: Commuter conversion with monthly trials'
        WHEN casual_trips >= 30 AND (casual_morning_rush + casual_evening_rush) * 100.0 / NULLIF(casual_trips, 0) > 50 
        THEN 'Rush Hour Campaign: Peak time membership benefits'
        WHEN route_distance_miles BETWEEN 1 AND 3 AND casual_trips >= 25
        THEN 'Distance Target: Perfect commute distance promotion'
        ELSE 'Secondary Target: General awareness campaigns'
    END as campaign_strategy

FROM route_base_metrics
WHERE casual_trips >= 10  -- Focus on routes with meaningful casual usage
ORDER BY 
    (
        (LEAST(casual_trips / 100.0, 1.0) * 40) +
        ((casual_weekday_trips * 100.0 / NULLIF(casual_trips, 0)) / 100.0 * 35) +
        (((casual_morning_rush + casual_evening_rush) * 100.0 / NULLIF(casual_trips, 0)) / 100.0 * 25)
    ) DESC, 
    casual_trips DESC
LIMIT 50;
