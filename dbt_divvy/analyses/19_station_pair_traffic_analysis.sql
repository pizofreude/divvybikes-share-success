-- Business Question 5: Geographic Conversion Potential - Station Pair Analysis
-- File: 19_station_pair_traffic_analysis.sql
-- Purpose: Analyze high-traffic station pairs for corridor marketing campaigns

WITH station_pair_metrics AS (
    -- Calculate traffic between station pairs (bidirectional)
    SELECT 
        LEAST(t.start_station_id, t.end_station_id) || '-' || GREATEST(t.start_station_id, t.end_station_id) as station_pair_id,
        LEAST(t.start_station_id, t.end_station_id) as station_a_id,
        GREATEST(t.start_station_id, t.end_station_id) as station_b_id,
        
        -- Calculate average distance between stations using trip coordinates
        ROUND(
            (3959 * ACOS(
                COS(RADIANS(AVG(t.start_lat))) * COS(RADIANS(AVG(t.end_lat))) * 
                COS(RADIANS(AVG(t.end_lng)) - RADIANS(AVG(t.start_lng))) + 
                SIN(RADIANS(AVG(t.start_lat))) * SIN(RADIANS(AVG(t.end_lat)))
            )), 2
        ) as pair_distance_miles,
        
        -- Traffic volume analysis
        COUNT(*) as total_pair_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) as casual_pair_trips,
        COUNT(CASE WHEN t.member_casual = 'member' THEN 1 END) as member_pair_trips,
        
        -- Directional flow analysis
        COUNT(CASE WHEN t.start_station_id = LEAST(t.start_station_id, t.end_station_id) AND t.member_casual = 'casual' THEN 1 END) as casual_a_to_b,
        COUNT(CASE WHEN t.start_station_id = GREATEST(t.start_station_id, t.end_station_id) AND t.member_casual = 'casual' THEN 1 END) as casual_b_to_a,
        
        -- Temporal patterns for commuter identification
        COUNT(CASE 
            WHEN t.member_casual = 'casual' 
                AND EXTRACT(DOW FROM t.started_at) BETWEEN 1 AND 5 
            THEN 1 
        END) as casual_weekday_trips,
        
        COUNT(CASE 
            WHEN t.member_casual = 'casual' 
                AND (EXTRACT(HOUR FROM t.started_at) BETWEEN 7 AND 9 
                     OR EXTRACT(HOUR FROM t.started_at) BETWEEN 17 AND 19)
            THEN 1 
        END) as casual_rush_hour_trips
        
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
        LEAST(t.start_station_id, t.end_station_id) || '-' || GREATEST(t.start_station_id, t.end_station_id),
        LEAST(t.start_station_id, t.end_station_id),
        GREATEST(t.start_station_id, t.end_station_id)
    HAVING COUNT(*) >= 30
        AND COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) >= 10
)

SELECT 
    station_pair_id,
    station_a_id,
    station_b_id,
    pair_distance_miles,
    total_pair_trips,
    casual_pair_trips,
    member_pair_trips,
    ROUND((casual_pair_trips * 100.0 / NULLIF(total_pair_trips, 0)), 2) as casual_percentage,
    
    -- Directional analysis
    casual_a_to_b,
    casual_b_to_a,
    ROUND((ABS(casual_a_to_b - casual_b_to_a) * 100.0 / NULLIF(GREATEST(casual_a_to_b, casual_b_to_a), 0)), 2) as directional_imbalance_percentage,
    
    -- Commuter behavior indicators
    casual_weekday_trips,
    ROUND((casual_weekday_trips * 100.0 / NULLIF(casual_pair_trips, 0)), 2) as casual_weekday_percentage,
    casual_rush_hour_trips,
    ROUND((casual_rush_hour_trips * 100.0 / NULLIF(casual_pair_trips, 0)), 2) as casual_rush_hour_percentage,
    
    -- Corridor conversion scoring
    ROUND(
        (
            (LEAST(casual_pair_trips / 150.0, 1.0) * 30) +
            ((casual_weekday_trips * 100.0 / NULLIF(casual_pair_trips, 0)) / 100.0 * 25) +
            ((casual_rush_hour_trips * 100.0 / NULLIF(casual_pair_trips, 0)) / 100.0 * 25) +
            (CASE WHEN pair_distance_miles BETWEEN 1 AND 4 THEN 1.0 ELSE 0.5 END * 20)
        ), 2
    ) as corridor_conversion_score,
    
    -- Corridor classification
    CASE 
        WHEN casual_pair_trips >= 100 AND casual_weekday_trips * 100.0 / NULLIF(casual_pair_trips, 0) >= 70 
        THEN 'High-Traffic Commuter Corridor'
        WHEN casual_pair_trips >= 75 AND casual_rush_hour_trips * 100.0 / NULLIF(casual_pair_trips, 0) >= 50
        THEN 'Rush Hour Corridor'
        WHEN pair_distance_miles BETWEEN 1 AND 3 AND casual_pair_trips >= 60
        THEN 'Short Distance Connector'
        WHEN casual_pair_trips * 100.0 / NULLIF(total_pair_trips, 0) > 70
        THEN 'Recreation Corridor'
        ELSE 'Mixed Usage Corridor'
    END as corridor_type,
    
    -- Campaign strategy recommendations
    CASE 
        WHEN casual_pair_trips >= 100 AND casual_weekday_trips * 100.0 / NULLIF(casual_pair_trips, 0) >= 75 
        THEN 'Priority Corridor: Comprehensive commuter conversion with corporate partnerships'
        WHEN casual_pair_trips >= 75 AND casual_rush_hour_trips * 100.0 / NULLIF(casual_pair_trips, 0) >= 60
        THEN 'Rush Hour Focus: Peak time membership benefits and express service'
        WHEN pair_distance_miles BETWEEN 1 AND 3 AND casual_pair_trips >= 50
        THEN 'Distance Optimization: Perfect commute corridor marketing'
        WHEN ABS(casual_a_to_b - casual_b_to_a) * 100.0 / NULLIF(GREATEST(casual_a_to_b, casual_b_to_a), 0) < 20
        THEN 'Balanced Flow: Round-trip commuter targeting'
        ELSE 'Secondary Corridor: General awareness and trial campaigns'
    END as campaign_strategy,
    
    -- Estimated conversion potential
    ROUND(casual_pair_trips * 
        CASE 
            WHEN corridor_conversion_score >= 75 THEN 0.20
            WHEN corridor_conversion_score >= 65 THEN 0.15
            WHEN corridor_conversion_score >= 55 THEN 0.12
            WHEN corridor_conversion_score >= 45 THEN 0.08
            ELSE 0.05
        END, 0
    ) as estimated_monthly_conversions

FROM station_pair_metrics
WHERE casual_pair_trips >= 20  -- Focus on corridors with meaningful casual usage
ORDER BY corridor_conversion_score DESC, casual_pair_trips DESC
LIMIT 50;
