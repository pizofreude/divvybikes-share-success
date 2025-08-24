/*
BUSINESS QUESTION 2D: Geographic Hotspots with High Casual Usage but Low Member Penetration
==========================================================================================

INSIGHT OBJECTIVE:
Identify geographic areas (stations/neighborhoods) with high casual ridership but 
disproportionately low member adoption. Focus on untapped conversion opportunities.

MARKETING APPLICATION:
- Target specific geographic areas for concentrated conversion campaigns
- Deploy location-based marketing (geofencing, local partnerships)
- Identify areas for physical marketing presence (station advertising, events)
- Develop neighborhood-specific membership value propositions
*/

-- Geographic Conversion Opportunity Analysis (2024 Focus)
WITH station_usage_analysis AS (
    -- Analyze usage patterns by station
    SELECT 
        COALESCE(NULLIF(start_station_name, ''), 'Unknown Station') as station_name,
        COALESCE(start_station_id, 'unknown') as station_id,
        -- Member vs Casual usage
        COUNT(CASE WHEN member_casual = 'casual' THEN 1 END) as casual_trips,
        COUNT(CASE WHEN member_casual = 'member' THEN 1 END) as member_trips,
        COUNT(*) as total_trips,
        -- Usage intensity metrics
        COUNT(DISTINCT DATE(started_at)) as active_days,
        COUNT(DISTINCT CASE WHEN member_casual = 'casual' THEN DATE(started_at) END) as casual_active_days,
        COUNT(DISTINCT CASE WHEN member_casual = 'member' THEN DATE(started_at) END) as member_active_days,
        -- Trip characteristics by user type
        AVG(CASE WHEN member_casual = 'casual' THEN ride_length_minutes END) as casual_avg_duration,
        AVG(CASE WHEN member_casual = 'member' THEN ride_length_minutes END) as member_avg_duration,
        AVG(CASE WHEN member_casual = 'casual' THEN trip_distance_km END) as casual_avg_distance,
        AVG(CASE WHEN member_casual = 'member' THEN trip_distance_km END) as member_avg_distance,
        -- Peak usage patterns
        COUNT(CASE 
            WHEN member_casual = 'casual' 
                AND EXTRACT(dow FROM started_at) IN (0, 6) 
            THEN 1 
        END) as casual_weekend_trips,
        COUNT(CASE 
            WHEN member_casual = 'member' 
                AND EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
            THEN 1 
        END) as member_weekday_trips
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        COALESCE(NULLIF(start_station_name, ''), 'Unknown Station'),
        COALESCE(start_station_id, 'unknown')
),
geographic_conversion_metrics AS (
    -- Calculate conversion potential metrics for each station
    SELECT 
        station_name,
        station_id,
        casual_trips,
        member_trips,
        total_trips,
        active_days,
        casual_active_days,
        member_active_days,
        -- Calculate penetration and opportunity metrics
        ROUND(casual_trips * 100.0 / NULLIF(total_trips, 0), 2) as casual_percentage,
        ROUND(member_trips * 100.0 / NULLIF(total_trips, 0), 2) as member_percentage,
        -- Usage intensity indicators
        ROUND(casual_trips * 1.0 / NULLIF(casual_active_days, 0), 2) as casual_trips_per_active_day,
        ROUND(member_trips * 1.0 / NULLIF(member_active_days, 0), 2) as member_trips_per_active_day,
        -- Trip characteristics
        ROUND(casual_avg_duration, 2) as casual_avg_duration,
        ROUND(member_avg_duration, 2) as member_avg_duration,
        ROUND(casual_avg_distance, 2) as casual_avg_distance,
        ROUND(member_avg_distance, 2) as member_avg_distance,
        -- Pattern indicators
        ROUND(casual_weekend_trips * 100.0 / NULLIF(casual_trips, 0), 2) as casual_weekend_percentage,
        ROUND(member_weekday_trips * 100.0 / NULLIF(member_trips, 0), 2) as member_weekday_percentage,
        -- Geographic conversion opportunity score
        CASE 
            WHEN casual_trips >= 1000 AND (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 70 THEN 95
            WHEN casual_trips >= 500 AND (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 60 THEN 85
            WHEN casual_trips >= 300 AND (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 50 THEN 75
            WHEN casual_trips >= 200 AND (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 40 THEN 65
            WHEN casual_trips >= 100 AND (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 35 THEN 55
            ELSE 25
        END as geographic_opportunity_score,
        -- Market penetration gap
        CASE 
            WHEN (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 70 THEN 'Severe Under-Penetration (70%+ casual)'
            WHEN (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 60 THEN 'High Under-Penetration (60-69% casual)'
            WHEN (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 50 THEN 'Moderate Under-Penetration (50-59% casual)'
            WHEN (casual_trips * 100.0 / NULLIF(total_trips, 0)) >= 40 THEN 'Low Under-Penetration (40-49% casual)'
            ELSE 'Good Member Penetration (<40% casual)'
        END as penetration_gap_category
    FROM station_usage_analysis
    WHERE total_trips >= 50  -- Focus on stations with meaningful usage
),
neighborhood_clustering AS (
    -- Group nearby stations to identify geographic clusters
    SELECT 
        penetration_gap_category,
        geographic_opportunity_score,
        COUNT(*) as stations_in_category,
        SUM(casual_trips) as total_casual_trips,
        SUM(member_trips) as total_member_trips,
        SUM(total_trips) as total_area_trips,
        AVG(casual_percentage) as avg_casual_percentage,
        AVG(casual_trips_per_active_day) as avg_casual_intensity,
        AVG(casual_avg_duration) as avg_casual_duration,
        AVG(casual_weekend_percentage) as avg_weekend_usage,
        -- Revenue opportunity calculation
        SUM(casual_trips) * 15.0 as monthly_revenue_opportunity, -- Assume $15/month membership
        SUM(casual_trips) * 180.0 as annual_revenue_opportunity, -- $15 * 12 months
        -- Marketing investment recommendation
        CASE 
            WHEN COUNT(*) >= 10 AND SUM(casual_trips) >= 5000 THEN 'High Investment Zone'
            WHEN COUNT(*) >= 5 AND SUM(casual_trips) >= 2000 THEN 'Medium Investment Zone'
            WHEN COUNT(*) >= 3 AND SUM(casual_trips) >= 1000 THEN 'Targeted Investment Zone'
            ELSE 'Low Investment Zone'
        END as marketing_investment_level
    FROM geographic_conversion_metrics
    WHERE geographic_opportunity_score >= 55  -- Focus on significant opportunities
    GROUP BY penetration_gap_category, geographic_opportunity_score
),
high_opportunity_stations AS (
    -- Identify specific high-opportunity stations for detailed targeting
    SELECT 
        'HIGH_OPPORTUNITY_STATIONS' as analysis_type,
        station_name,
        penetration_gap_category,
        casual_trips,
        member_trips,
        total_trips,
        casual_percentage,
        geographic_opportunity_score,
        casual_trips_per_active_day,
        casual_avg_duration,
        casual_weekend_percentage,
        -- Marketing strategy recommendations
        CASE 
            WHEN casual_weekend_percentage >= 60 THEN 'Recreation/Tourism Hub - Lifestyle Messaging'
            WHEN casual_trips_per_active_day >= 3 THEN 'High-Intensity Area - Cost Savings Focus'
            WHEN casual_avg_duration >= 30 THEN 'Long-Trip Users - Convenience Benefits'
            ELSE 'General Market - Mixed Messaging'
        END as recommended_strategy,
        -- Campaign priority
        CASE 
            WHEN geographic_opportunity_score >= 85 AND casual_trips >= 500 THEN 'Immediate Priority'
            WHEN geographic_opportunity_score >= 75 AND casual_trips >= 300 THEN 'High Priority'
            WHEN geographic_opportunity_score >= 65 AND casual_trips >= 200 THEN 'Medium Priority'
            ELSE 'Low Priority'
        END as campaign_priority,
        -- Estimated conversion potential
        ROUND(casual_trips * 0.15, 0) as conservative_conversion_estimate, -- 15% conversion rate
        ROUND(casual_trips * 0.25, 0) as optimistic_conversion_estimate,   -- 25% conversion rate
        -- Monthly revenue potential
        ROUND(casual_trips * 0.20 * 15, 0) as estimated_monthly_revenue_impact -- 20% avg conversion
    FROM geographic_conversion_metrics
    WHERE geographic_opportunity_score >= 75
        AND casual_trips >= 200
)

-- Main Results: Geographic Conversion Opportunities
SELECT 
    'GEOGRAPHIC_OPPORTUNITY_SUMMARY' as analysis_type,
    penetration_gap_category as station_name,
    marketing_investment_level as recommended_strategy,
    stations_in_category,
    total_casual_trips as casual_trips,
    total_member_trips as member_trips,
    total_area_trips as total_trips,
    avg_casual_percentage as casual_percentage,
    ROUND(AVG(geographic_opportunity_score), 2) as geographic_opportunity_score,
    avg_casual_intensity as casual_trips_per_active_day,
    avg_casual_duration,
    avg_weekend_usage as casual_weekend_percentage,
    'Cluster Analysis' as campaign_priority,
    ROUND(total_casual_trips * 0.15, 0) as conservative_conversion_estimate,
    ROUND(total_casual_trips * 0.25, 0) as optimistic_conversion_estimate,
    ROUND(monthly_revenue_opportunity, 0) as estimated_monthly_revenue_impact
FROM neighborhood_clustering
GROUP BY 
    penetration_gap_category,
    marketing_investment_level,
    stations_in_category,
    total_casual_trips,
    total_member_trips,
    total_area_trips,
    avg_casual_percentage,
    avg_casual_intensity,
    avg_casual_duration,
    avg_weekend_usage,
    monthly_revenue_opportunity

UNION ALL

-- High-Priority Individual Station Targets
SELECT 
    analysis_type,
    station_name,
    recommended_strategy,
    1 as stations_in_category,
    casual_trips,
    member_trips,
    total_trips,
    casual_percentage,
    geographic_opportunity_score,
    casual_trips_per_active_day,
    casual_avg_duration,
    casual_weekend_percentage,
    campaign_priority,
    conservative_conversion_estimate,
    optimistic_conversion_estimate,
    estimated_monthly_revenue_impact
FROM high_opportunity_stations

ORDER BY 
    analysis_type, geographic_opportunity_score DESC, casual_trips DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

GEOGRAPHIC OPPORTUNITY ZONES:
- Severe Under-Penetration (70%+ casual): Tourist/recreational areas
- High Under-Penetration (60-69% casual): Mixed-use neighborhoods  
- Moderate Under-Penetration (50-59% casual): Emerging business districts
- Revenue hotspots: Stations with 500+ casual trips per month

LOCATION-BASED STRATEGIES:
- Recreation Hubs: Weekend-focused, lifestyle messaging, trial memberships
- High-Intensity Areas: Cost-benefit analysis, savings calculators
- Tourist Areas: Visitor programs, short-term membership options
- Residential Zones: Convenience and commute benefits

INVESTMENT PRIORITIZATION:
- High Investment Zones: 10+ stations, 5000+ monthly casual trips
- Medium Investment Zones: 5+ stations, 2000+ monthly casual trips
- Targeted Investment: 3+ stations, 1000+ monthly casual trips
- Focus areas: 200+ casual trips per station with 75+ opportunity score

KEY MARKETING ACTIONS:
1. **Geographic Clustering**: Target clusters of high-opportunity stations
2. **Location-Based Advertising**: Geofenced digital campaigns around target stations
3. **Physical Presence**: Station signage, local events, street team activation
4. **Neighborhood Partnerships**: Local business collaborations for member benefits
5. **Area-Specific Messaging**: Tailor campaigns to local usage patterns and demographics
6. **Pilot Programs**: Test conversion strategies in highest-opportunity zones first
*/
