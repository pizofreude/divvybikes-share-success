/*
Business Question 5 Analysis: Geographic Conversion Potential
Query 20: Neighborhood Characteristics and Conversion Analysis

INSIGHT OBJECTIVE:
Analyze neighborhood-level characteristics and demographics to identify areas with
highest conversion potential based on geographic clustering of high-casual-usage
stations, proximity to business districts, transportation hubs, and community features
that correlate with membership conversion success.

MARKETING APPLICATION:
- Deploy neighborhood-wide marketing campaigns with localized messaging
- Partner with community organizations and local businesses for membership drives
- Create neighborhood-specific membership packages and benefits
- Implement geo-targeted digital advertising based on neighborhood conversion profiles
- Optimize station placement and capacity planning for high-conversion neighborhoods

FILE PATH: dbt_divvy/analyses/20_neighborhood_conversion_characteristics.sql
*/

WITH neighborhood_trip_analysis AS (
    -- Aggregate trip data by neighborhood clusters using trip coordinates directly
    SELECT 
        CAST(FLOOR(t.start_lat * 100) AS VARCHAR) || '_' || CAST(FLOOR(t.start_lng * 100) AS VARCHAR) as neighborhood_cluster_id,
        AVG(t.start_lat) as neighborhood_center_lat,
        AVG(t.start_lng) as neighborhood_center_lng,
        COUNT(DISTINCT t.start_station_id) as stations_in_cluster,
        
        -- Create neighborhood identifier
        'Neighborhood_' || CAST(FLOOR(t.start_lat * 100) AS VARCHAR) || '_' || CAST(FLOOR(t.start_lng * 100) AS VARCHAR) as neighborhood_identifier,
        
        -- Trip volume metrics
        COUNT(*) as total_neighborhood_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) as casual_neighborhood_trips,
        COUNT(CASE WHEN t.member_casual = 'member' THEN 1 END) as member_neighborhood_trips,
        
        -- Estimate unique usage patterns (proxy for user analysis)
        COUNT(DISTINCT DATE(t.started_at) || '_' || t.start_station_id || '_' || EXTRACT(hour FROM t.started_at)) as unique_usage_patterns,
        COUNT(DISTINCT CASE WHEN t.member_casual = 'casual' THEN DATE(t.started_at) || '_' || t.start_station_id END) as unique_casual_usage_days,
        COUNT(DISTINCT CASE WHEN t.member_casual = 'member' THEN DATE(t.started_at) || '_' || t.start_station_id END) as unique_member_usage_days,
        
        -- Temporal usage patterns for casual riders
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(dow FROM t.started_at) IN (1,2,3,4,5) THEN 1 END) as casual_weekday_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(dow FROM t.started_at) IN (0,6) THEN 1 END) as casual_weekend_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 7 AND 9 THEN 1 END) as casual_morning_commute,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 17 AND 19 THEN 1 END) as casual_evening_commute,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 10 AND 16 THEN 1 END) as casual_midday_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(hour FROM t.started_at) BETWEEN 19 AND 23 THEN 1 END) as casual_evening_leisure,
        
        -- Trip quality and duration analysis
        COUNT(CASE WHEN t.member_casual = 'casual' AND t.ride_length_minutes BETWEEN 5 AND 45 THEN 1 END) as casual_quality_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND t.ride_length_minutes BETWEEN 10 AND 30 THEN 1 END) as casual_optimal_trips,
        ROUND(AVG(CASE WHEN t.member_casual = 'casual' THEN t.ride_length_minutes END), 2) as avg_casual_duration,
        ROUND(AVG(CASE WHEN t.member_casual = 'member' THEN t.ride_length_minutes END), 2) as avg_member_duration,
        
        -- Cross-neighborhood travel patterns (as departure point)
        COUNT(DISTINCT CASE 
            WHEN t.member_casual = 'casual' AND t.end_station_id IS NOT NULL AND t.end_lat IS NOT NULL
            THEN CAST(FLOOR(t.end_lat * 100) AS VARCHAR) || '_' || CAST(FLOOR(t.end_lng * 100) AS VARCHAR)
        END) as destinations_reached_by_casual,
        
        -- Seasonal usage distribution
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(month FROM t.started_at) IN (3,4,5) THEN 1 END) as casual_spring_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(month FROM t.started_at) IN (6,7,8) THEN 1 END) as casual_summer_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(month FROM t.started_at) IN (9,10,11) THEN 1 END) as casual_fall_trips,
        COUNT(CASE WHEN t.member_casual = 'casual' AND EXTRACT(month FROM t.started_at) IN (12,1,2) THEN 1 END) as casual_winter_trips,
        
        -- Year-over-year growth analysis
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2024 AND t.member_casual = 'casual' THEN 1 END) as casual_trips_2024,
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2023 AND t.member_casual = 'casual' THEN 1 END) as casual_trips_2023,
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2024 AND t.member_casual = 'member' THEN 1 END) as member_trips_2024,
        COUNT(CASE WHEN EXTRACT(year FROM t.started_at) = 2023 AND t.member_casual = 'member' THEN 1 END) as member_trips_2023
        
    FROM "divvy"."public_gold"."trips_enhanced" t
    WHERE t.started_at >= '2023-01-01'
        AND t.started_at < '2025-01-01'
        AND t.ride_length_minutes BETWEEN 2 AND 120
        AND t.start_lat IS NOT NULL 
        AND t.start_lng IS NOT NULL
    GROUP BY 
        CAST(FLOOR(t.start_lat * 100) AS VARCHAR) || '_' || CAST(FLOOR(t.start_lng * 100) AS VARCHAR),
        'Neighborhood_' || CAST(FLOOR(t.start_lat * 100) AS VARCHAR) || '_' || CAST(FLOOR(t.start_lng * 100) AS VARCHAR)
    HAVING COUNT(*) >= 50  -- More reasonable threshold
        AND COUNT(CASE WHEN t.member_casual = 'casual' THEN 1 END) >= 20  -- Lower casual threshold
),
neighborhood_characteristics_analysis AS (
    -- Calculate neighborhood-specific characteristics and conversion indicators
    SELECT 
        *,
        
        -- Basic conversion metrics
        ROUND((casual_neighborhood_trips * 100.0 / NULLIF(total_neighborhood_trips, 0)), 2) as casual_usage_percentage,
        ROUND((member_neighborhood_trips * 100.0 / NULLIF(total_neighborhood_trips, 0)), 2) as member_usage_percentage,
        ROUND((unique_casual_usage_days * 100.0 / NULLIF(unique_usage_patterns, 0)), 2) as casual_usage_pattern_percentage,
        
        -- Usage intensity and engagement (using trip frequency as proxy)
        ROUND(casual_neighborhood_trips * 1.0 / NULLIF(unique_casual_usage_days, 0), 2) as trips_per_casual_day,
        ROUND(member_neighborhood_trips * 1.0 / NULLIF(unique_member_usage_days, 0), 2) as trips_per_member_day,
        ROUND(total_neighborhood_trips * 1.0 / NULLIF(stations_in_cluster, 0), 2) as trips_per_station,
        
        -- Temporal behavior analysis
        ROUND((casual_weekday_trips * 100.0 / NULLIF(casual_neighborhood_trips, 0)), 2) as casual_weekday_percentage,
        ROUND(((casual_morning_commute + casual_evening_commute) * 100.0 / NULLIF(casual_neighborhood_trips, 0)), 2) as casual_commuter_percentage,
        ROUND((casual_midday_trips * 100.0 / NULLIF(casual_neighborhood_trips, 0)), 2) as casual_midday_percentage,
        ROUND((casual_evening_leisure * 100.0 / NULLIF(casual_neighborhood_trips, 0)), 2) as casual_leisure_percentage,
        ROUND((casual_quality_trips * 100.0 / NULLIF(casual_neighborhood_trips, 0)), 2) as casual_quality_percentage,
        
        -- Market penetration analysis
        ROUND((member_neighborhood_trips * 100.0 / NULLIF(total_neighborhood_trips, 0)) - 
              (casual_neighborhood_trips * 100.0 / NULLIF(total_neighborhood_trips, 0)), 2) as member_penetration_gap,
        
        -- Network connectivity analysis
        ROUND(destinations_reached_by_casual * 1.0 / NULLIF(unique_casual_usage_days, 0), 2) as connectivity_per_usage_day,
        destinations_reached_by_casual as neighborhood_connectivity,
        
        -- Seasonal concentration analysis
        ROUND((GREATEST(casual_spring_trips, casual_summer_trips, casual_fall_trips, casual_winter_trips) * 100.0 / 
               NULLIF(casual_neighborhood_trips, 0)), 2) as peak_season_concentration,
        
        -- Growth trend analysis
        ROUND(((casual_trips_2024 - casual_trips_2023) * 100.0 / NULLIF(casual_trips_2023, 0)), 2) as yoy_casual_growth_percent,
        ROUND(((member_trips_2024 - member_trips_2023) * 100.0 / NULLIF(member_trips_2023, 0)), 2) as yoy_member_growth_percent
        
    FROM neighborhood_trip_analysis
)

SELECT 
    'NEIGHBORHOOD_CONVERSION_ANALYSIS' as analysis_type,
    neighborhood_cluster_id,
    neighborhood_center_lat,
    neighborhood_center_lng,
    LEFT(neighborhood_identifier, 100) as key_stations,
    stations_in_cluster,
    total_neighborhood_trips,
    casual_neighborhood_trips,
    member_neighborhood_trips,
    unique_casual_usage_days,
    unique_member_usage_days,
    casual_usage_percentage,
    member_usage_percentage,
    member_penetration_gap,
    trips_per_casual_day,
    trips_per_station,
    casual_weekday_percentage,
    casual_commuter_percentage,
    casual_midday_percentage,
    casual_leisure_percentage,
    casual_quality_percentage,
    avg_casual_duration,
    neighborhood_connectivity,
    connectivity_per_usage_day,
    peak_season_concentration,
    yoy_casual_growth_percent,
    yoy_member_growth_percent,
    
    -- Neighborhood conversion potential scoring (0-100 scale)
    CASE 
        WHEN casual_neighborhood_trips >= 1000 AND member_penetration_gap >= 30 AND trips_per_casual_day >= 2.5 
            THEN 95  -- Highest neighborhood potential
        WHEN casual_neighborhood_trips >= 750 AND casual_commuter_percentage >= 25 AND trips_per_casual_day >= 2.0 
            THEN 85  -- High neighborhood potential
        WHEN casual_neighborhood_trips >= 500 AND casual_quality_percentage >= 75 AND unique_casual_usage_days >= 100 
            THEN 75  -- Good neighborhood potential
        WHEN casual_neighborhood_trips >= 300 AND casual_weekday_percentage >= 60 AND stations_in_cluster >= 3 
            THEN 65  -- Moderate neighborhood potential
        WHEN casual_neighborhood_trips >= 200 AND unique_casual_usage_days >= 50 
            THEN 45  -- Lower neighborhood potential
        ELSE 25  -- Limited neighborhood potential
    END as neighborhood_conversion_score,
    
    -- Neighborhood type classification
    CASE 
        WHEN casual_commuter_percentage >= 30 AND casual_weekday_percentage >= 70 
            THEN 'Business District - Commuter Hub'
        WHEN casual_leisure_percentage >= 40 AND casual_weekend_trips >= casual_weekday_trips * 0.8 
            THEN 'Entertainment District - Leisure Hub'
        WHEN casual_midday_percentage >= 35 AND stations_in_cluster >= 5 
            THEN 'Commercial District - Shopping & Dining Hub'
        WHEN connectivity_per_usage_day >= 2.0 AND neighborhood_connectivity >= 10 
            THEN 'Transit Hub - Transportation Connector'
        WHEN trips_per_casual_day >= 3.0 AND casual_quality_percentage >= 80 
            THEN 'Residential District - Regular Usage Community'
        WHEN yoy_casual_growth_percent >= 50 
            THEN 'Emerging District - Growing Usage Area'
        ELSE 'Mixed-Use District - General Community Hub'
    END as neighborhood_type,
    
    -- Targeted campaign strategy by neighborhood characteristics
    CASE 
        WHEN casual_commuter_percentage >= 30 
            THEN 'Commuter Neighborhood Campaign - Rush hour convenience and time savings'
        WHEN casual_leisure_percentage >= 40 
            THEN 'Leisure Neighborhood Campaign - Recreation and entertainment access'
        WHEN casual_midday_percentage >= 35 
            THEN 'Business Neighborhood Campaign - Professional networking and efficiency'
        WHEN connectivity_per_usage_day >= 2.0 
            THEN 'Transit Neighborhood Campaign - Seamless city-wide connectivity'
        WHEN trips_per_casual_day >= 3.0 
            THEN 'Frequent User Neighborhood Campaign - Heavy usage rewards and benefits'
        WHEN yoy_casual_growth_percent >= 50 
            THEN 'Growth Neighborhood Campaign - Early adopter advantages'
        ELSE 'Community Neighborhood Campaign - Local partnership and convenience'
    END as neighborhood_campaign_strategy,
    
    -- Community partnership opportunities
    CASE 
        WHEN casual_commuter_percentage >= 25 
            THEN 'Corporate Partnerships - Office buildings and business associations'
        WHEN casual_leisure_percentage >= 35 
            THEN 'Entertainment Partnerships - Venues, restaurants, and cultural institutions'
        WHEN casual_midday_percentage >= 30 
            THEN 'Commercial Partnerships - Shopping centers and professional services'
        WHEN connectivity_per_usage_day >= 2.5 
            THEN 'Transit Partnerships - Public transportation and mobility services'
        WHEN trips_per_casual_day >= 3.0 
            THEN 'Residential Partnerships - Housing developments and community centers'
        ELSE 'General Partnerships - Local businesses and community organizations'
    END as partnership_opportunities,
    
    -- Marketing deployment strategy
    CASE 
        WHEN neighborhood_conversion_score >= 85 AND casual_neighborhood_trips >= 750 
            THEN 'Intensive Deployment - Multi-channel neighborhood saturation'
        WHEN neighborhood_conversion_score >= 75 
            THEN 'Priority Deployment - Focused high-impact campaigns'
        WHEN neighborhood_conversion_score >= 65 AND unique_casual_usage_days >= 75 
            THEN 'Standard Deployment - Regular neighborhood targeting'
        WHEN neighborhood_conversion_score >= 45 
            THEN 'Selective Deployment - Targeted opportunity campaigns'
        ELSE 'Monitor Deployment - Limited neighborhood focus'
    END as deployment_strategy,
    
    -- Estimated conversion targets (using usage patterns as proxy)
    ROUND(unique_casual_usage_days * 0.8 * 
        CASE 
            WHEN neighborhood_conversion_score >= 85 THEN 0.35  -- 35% conversion for top neighborhoods
            WHEN neighborhood_conversion_score >= 75 THEN 0.28  -- 28% conversion for good neighborhoods
            WHEN neighborhood_conversion_score >= 65 THEN 0.22  -- 22% conversion for moderate neighborhoods
            WHEN neighborhood_conversion_score >= 45 THEN 0.15  -- 15% conversion for lower neighborhoods
            ELSE 0.08  -- 8% conversion for limited neighborhoods
        END) as estimated_neighborhood_conversions,
    
    -- Investment priority and budget allocation
    CASE 
        WHEN neighborhood_conversion_score >= 85 AND casual_neighborhood_trips >= 1000 
            THEN 'High Priority Investment - Major Neighborhood Opportunity'
        WHEN neighborhood_conversion_score >= 75 AND unique_casual_usage_days >= 100 
            THEN 'Priority Investment - Strong Neighborhood Potential'
        WHEN neighborhood_conversion_score >= 65 AND stations_in_cluster >= 4 
            THEN 'Standard Investment - Good Neighborhood Coverage'
        WHEN neighborhood_conversion_score >= 45 
            THEN 'Selective Investment - Targeted Neighborhood Focus'
        ELSE 'Monitor Investment - Limited Neighborhood Priority'
    END as investment_priority,
    
    -- Operational recommendations for neighborhood optimization
    CASE 
        WHEN trips_per_station >= 500 AND stations_in_cluster <= 3 
            THEN 'Expand station network - High demand low coverage area'
        WHEN casual_quality_percentage <= 60 
            THEN 'Improve station maintenance - Low trip quality area'
        WHEN connectivity_per_usage_day >= 2.5 
            THEN 'Enhance connectivity - Strong multi-destination usage'
        WHEN yoy_casual_growth_percent >= 50 
            THEN 'Scale capacity - Rapidly growing usage area'
        ELSE 'Maintain operations - Stable neighborhood performance'
    END as operational_recommendation,
    
    -- Long-term strategic development
    CASE 
        WHEN neighborhood_conversion_score >= 85 
            THEN 'Community Engagement - Build local brand ambassador program'
        WHEN casual_commuter_percentage >= 30 
            THEN 'Corporate Integration - Develop business district partnerships'
        WHEN yoy_casual_growth_percent >= 50 
            THEN 'Growth Strategy - Expand infrastructure to support demand'
        WHEN connectivity_per_usage_day >= 2.0 
            THEN 'Network Development - Enhance regional connectivity'
        ELSE 'Market Development - Build awareness and trial programs'
    END as long_term_strategy

FROM neighborhood_characteristics_analysis
ORDER BY neighborhood_conversion_score DESC, casual_neighborhood_trips DESC
LIMIT 50;
