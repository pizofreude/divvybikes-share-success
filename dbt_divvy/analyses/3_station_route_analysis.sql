/*
BUSINESS QUESTION 1C: Popular Routes and Station Analysis
========================================================

INSIGHT OBJECTIVE:
Identify the most popular routes and stations by user type to understand geographical
usage patterns and preferences. This reveals commute corridors vs recreational areas.

MARKETING APPLICATION:
- Deploy targeted station advertising at high casual-usage locations
- Identify conversion opportunities at mixed-usage stations
- Develop location-based membership promotions
- Create route-specific marketing campaigns (commute vs recreational)
*/

-- Popular Stations and Routes Analysis (2024 Focus)
WITH station_usage AS (
    SELECT 
        member_casual,
        start_station_name,
        start_station_id,
        end_station_name, 
        end_station_id,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration_minutes,
        AVG(trip_distance_km) as avg_distance_km,
        -- Route classification
        CASE 
            WHEN start_station_id = end_station_id THEN 'Round Trip'
            ELSE 'Point-to-Point'
        END as route_type
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) = 2024
        AND start_station_name IS NOT NULL 
        AND end_station_name IS NOT NULL
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, start_station_name, start_station_id, 
             end_station_name, end_station_id, route_type
),
top_start_stations AS (
    SELECT 
        member_casual,
        start_station_name,
        start_station_id,
        SUM(trip_count) as total_starts,
        AVG(avg_duration_minutes) as avg_duration,
        AVG(avg_distance_km) as avg_distance,
        RANK() OVER (PARTITION BY member_casual ORDER BY SUM(trip_count) DESC) as station_rank
    FROM station_usage
    GROUP BY member_casual, start_station_name, start_station_id
),
top_routes AS (
    SELECT 
        member_casual,
        start_station_name,
        end_station_name,
        route_type,
        trip_count,
        ROUND(avg_duration_minutes, 2) as avg_duration,
        ROUND(avg_distance_km, 2) as avg_distance,
        RANK() OVER (PARTITION BY member_casual ORDER BY trip_count DESC) as route_rank
    FROM station_usage
    WHERE route_type = 'Point-to-Point'  -- Focus on actual routes, not round trips
),
station_conversion_potential AS (
    -- Identify stations with high casual usage that could be conversion targets
    SELECT 
        tss_casual.start_station_name,
        tss_casual.start_station_id,
        tss_casual.total_starts as casual_starts,
        COALESCE(tss_member.total_starts, 0) as member_starts,
        tss_casual.total_starts + COALESCE(tss_member.total_starts, 0) as total_starts,
        ROUND(
            tss_casual.total_starts * 100.0 / 
            (tss_casual.total_starts + COALESCE(tss_member.total_starts, 0)), 2
        ) as casual_percentage,
        CASE 
            WHEN tss_casual.total_starts >= 1000 AND 
                 tss_casual.total_starts * 100.0 / 
                 (tss_casual.total_starts + COALESCE(tss_member.total_starts, 0)) >= 40
            THEN 'High Conversion Potential'
            WHEN tss_casual.total_starts >= 500 AND 
                 tss_casual.total_starts * 100.0 / 
                 (tss_casual.total_starts + COALESCE(tss_member.total_starts, 0)) >= 30
            THEN 'Medium Conversion Potential'
            ELSE 'Low Conversion Potential'
        END as conversion_potential
    FROM top_start_stations tss_casual
    LEFT JOIN top_start_stations tss_member 
        ON tss_casual.start_station_id = tss_member.start_station_id 
        AND tss_member.member_casual = 'member'
    WHERE tss_casual.member_casual = 'casual'
        AND tss_casual.station_rank <= 50  -- Top 50 casual stations
)

-- Main Results: Combined Analysis
SELECT 
    'TOP_STATIONS' as analysis_type,
    member_casual,
    start_station_name as location_name,
    NULL as end_location,
    'Station' as location_type,
    total_starts as usage_count,
    ROUND(avg_duration, 2) as avg_duration_minutes,
    ROUND(avg_distance, 2) as avg_distance_km,
    station_rank as popularity_rank,
    NULL as conversion_potential
FROM top_start_stations
WHERE station_rank <= 10  -- Top 10 stations per user type

UNION ALL

SELECT 
    'TOP_ROUTES' as analysis_type,
    member_casual,
    start_station_name as location_name,
    end_station_name as end_location,
    'Route' as location_type,
    trip_count as usage_count,
    avg_duration as avg_duration_minutes,
    avg_distance as avg_distance_km,
    route_rank as popularity_rank,
    NULL as conversion_potential
FROM top_routes
WHERE route_rank <= 10  -- Top 10 routes per user type

UNION ALL

SELECT 
    'CONVERSION_TARGETS' as analysis_type,
    'casual' as member_casual,
    start_station_name as location_name,
    NULL as end_location,
    'High-Potential Station' as location_type,
    casual_starts as usage_count,
    NULL as avg_duration_minutes,
    NULL as avg_distance_km,
    ROW_NUMBER() OVER (ORDER BY casual_starts DESC) as popularity_rank,
    conversion_potential
FROM station_conversion_potential
WHERE conversion_potential IN ('High Conversion Potential', 'Medium Conversion Potential')

ORDER BY analysis_type, member_casual, popularity_rank;

/*
ADDITIONAL ANALYSIS: Round Trip vs Point-to-Point Preferences
*/
-- Separate query for round trip analysis
WITH station_usage_summary AS (
    SELECT 
        member_casual,
        CASE 
            WHEN start_station_id = end_station_id THEN 'Round Trip'
            ELSE 'Point-to-Point'
        END as route_type,
        AVG(ride_length_minutes) as avg_duration_minutes,
        AVG(trip_distance_km) as avg_distance_km
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) = 2024
        AND start_station_name IS NOT NULL 
        AND end_station_name IS NOT NULL
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, route_type
)
SELECT 
    'ROUTE_TYPE_ANALYSIS' as analysis_type,
    member_casual,
    route_type,
    COUNT(*) as trip_count,
    ROUND(AVG(avg_duration_minutes), 2) as avg_duration,
    ROUND(AVG(avg_distance_km), 2) as avg_distance,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as percentage_of_trips
FROM station_usage_summary
GROUP BY member_casual, route_type
ORDER BY member_casual, route_type;

/*
EXPECTED INSIGHTS FOR MARKETING:
- Tourist/recreational areas likely dominated by casual riders
- Business districts and transit hubs likely show higher member usage  
- Mixed-usage stations represent prime conversion opportunities
- Route patterns reveal commute corridors vs recreational paths

KEY MARKETING ACTIONS:
1. **Station Advertising**: Deploy conversion-focused ads at high-casual-usage stations
2. **Geofenced Digital Campaigns**: Target smartphone users near conversion-potential stations
3. **Route-Specific Promotions**: Create "commuter route" trials for popular casual routes
4. **Partner Integrations**: Work with businesses near high-conversion stations for membership perks
5. **Seasonal Station Focus**: Adjust station targeting based on seasonal usage patterns
6. **Round Trip Promotions**: Target casual round-trip users with "exploration membership" packages
*/
