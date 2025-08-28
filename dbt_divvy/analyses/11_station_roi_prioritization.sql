/*
BUSINESS QUESTION 3C: Station-Based Marketing ROI Prioritization

OBJECTIVE: Identify high-ROI station locations for targeted marketing investments:
- Station-level conversion potential and cost-effectiveness
- Geographic clustering for efficient campaign deployment
- Usage density and member penetration gap analysis
- Marketing infrastructure investment prioritization

MARKETING APPLICATION:
- Prioritize physical marketing placements (signage, kiosks, QR codes)
- Focus street team and promotional events on high-ROI locations
- Allocate station-specific digital advertising budgets
- Identify expansion opportunities for membership drive stations

EXPECTED INSIGHTS:
- High-Traffic Tourist Stations: Maximum visibility, seasonal campaign focus
- Commuter Hub Stations: Consistent volume, year-round conversion opportunities
- Underutilized High-Potential: Low current usage but high growth potential
- Neighborhood Gateway Stations: Community-focused, local partnership opportunities
*/

WITH station_usage_analysis AS (
    -- Comprehensive station usage analysis for 2024
    SELECT 
        COALESCE(start_station_name, 'Unknown Station') as station_name,
        start_station_id,
        
        -- Usage volume metrics
        COUNT(*) as total_casual_trips_2024,
        COUNT(DISTINCT DATE(started_at)) as active_days,
        COUNT(DISTINCT 
            CASE 
                WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
                ELSE start_station_name 
            END
        ) as unique_casual_riders,
        
        -- Usage intensity metrics
        COUNT(*) * 1.0 / COUNT(DISTINCT DATE(started_at)) as avg_trips_per_active_day,
        AVG(ride_length_minutes) as avg_trip_duration,
        AVG(trip_distance_km) as avg_trip_distance,
        
        -- Temporal usage patterns
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 THEN 1 ELSE 0 
        END) as weekday_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) THEN 1 ELSE 0 
        END) as weekend_trips,
        
        -- Peak usage indicators
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 THEN 1 ELSE 0 
        END) as morning_peak_trips,
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 THEN 1 ELSE 0 
        END) as evening_peak_trips,
        
        -- Seasonal usage distribution
        SUM(CASE 
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 1 ELSE 0 
        END) as summer_trips,
        SUM(CASE 
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 1 ELSE 0 
        END) as spring_trips,
        
        -- Usage quality indicators
        COUNT(CASE 
            WHEN ride_length_minutes BETWEEN 5 AND 45 THEN 1  -- Practical usage range
        END) as practical_usage_trips,
        
        -- Geographic connectivity
        COUNT(DISTINCT end_station_id) as unique_destinations
        
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        COALESCE(start_station_name, 'Unknown Station'),
        start_station_id
),
member_comparison_baseline AS (
    -- Get member usage at same stations for comparison
    SELECT 
        COALESCE(start_station_name, 'Unknown Station') as station_name,
        COUNT(*) as total_member_trips_2024,
        COUNT(DISTINCT 
            CASE 
                WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
                ELSE start_station_name 
            END
        ) as unique_member_riders,
        AVG(ride_length_minutes) as member_avg_duration
        
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'member'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY COALESCE(start_station_name, 'Unknown Station')
),
station_opportunity_scoring AS (
    -- Calculate opportunity scores and ROI metrics
    SELECT 
        sua.station_name,
        sua.total_casual_trips_2024,
        sua.unique_casual_riders,
        sua.avg_trips_per_active_day,
        ROUND(sua.avg_trip_duration, 2) as avg_trip_duration,
        sua.weekday_trips,
        sua.weekend_trips,
        sua.morning_peak_trips + sua.evening_peak_trips as commute_trips,
        sua.practical_usage_trips,
        
        -- Member comparison metrics
        COALESCE(mcb.total_member_trips_2024, 0) as total_member_trips_2024,
        COALESCE(mcb.unique_member_riders, 0) as unique_member_riders,
        
        -- Penetration gap analysis
        CASE 
            WHEN (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0)) > 0
            THEN sua.total_casual_trips_2024 * 100.0 / 
                 (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0))
            ELSE 100.0
        END as casual_percentage,
        
        -- Volume opportunity score (0-100)
        LEAST(100, 
            CASE 
                WHEN sua.total_casual_trips_2024 >= 5000 THEN 95
                WHEN sua.total_casual_trips_2024 >= 2000 THEN 85
                WHEN sua.total_casual_trips_2024 >= 1000 THEN 75
                WHEN sua.total_casual_trips_2024 >= 500 THEN 65
                WHEN sua.total_casual_trips_2024 >= 200 THEN 55
                ELSE 35
            END
        ) as volume_opportunity_score,
        
        -- Usage quality score (0-100)
        LEAST(100,
            (sua.practical_usage_trips * 100.0 / sua.total_casual_trips_2024) * 0.4 +  -- 40% practical usage
            (LEAST(sua.unique_destinations, 20) * 5) * 0.3 +  -- 30% destination diversity  
            (CASE 
                WHEN sua.avg_trips_per_active_day >= 10 THEN 100
                WHEN sua.avg_trips_per_active_day >= 5 THEN 80
                WHEN sua.avg_trips_per_active_day >= 2 THEN 60
                ELSE 30
            END) * 0.3  -- 30% daily intensity
        ) as usage_quality_score,
        
        -- Market penetration opportunity (higher casual % = higher opportunity)
        CASE 
            WHEN sua.total_casual_trips_2024 * 100.0 / 
                 (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0)) >= 80 THEN 95
            WHEN sua.total_casual_trips_2024 * 100.0 / 
                 (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0)) >= 70 THEN 85
            WHEN sua.total_casual_trips_2024 * 100.0 / 
                 (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0)) >= 60 THEN 75
            WHEN sua.total_casual_trips_2024 * 100.0 / 
                 (sua.total_casual_trips_2024 + COALESCE(mcb.total_member_trips_2024, 0)) >= 50 THEN 65
            ELSE 45
        END as penetration_opportunity_score
        
    FROM station_usage_analysis sua
    LEFT JOIN member_comparison_baseline mcb 
        ON sua.station_name = mcb.station_name
    WHERE sua.total_casual_trips_2024 >= 100  -- Focus on stations with meaningful usage
),
roi_prioritization AS (
    -- Calculate comprehensive ROI scores and marketing recommendations
    SELECT 
        station_name,
        total_casual_trips_2024,
        unique_casual_riders,
        ROUND(avg_trips_per_active_day, 2) as avg_trips_per_active_day,
        avg_trip_duration,
        ROUND(casual_percentage, 2) as casual_percentage,
        volume_opportunity_score,
        usage_quality_score,
        penetration_opportunity_score,
        
        -- Composite ROI score (weighted average)
        ROUND(
            (volume_opportunity_score * 0.4 +      -- 40% weight on volume
             usage_quality_score * 0.3 +          -- 30% weight on quality  
             penetration_opportunity_score * 0.3), -- 30% weight on penetration gap
            2
        ) as composite_roi_score,
        
        -- Station type classification
        CASE 
            WHEN weekend_trips > weekday_trips AND total_casual_trips_2024 >= 2000 
                THEN 'Tourist/Recreation Hub'
            WHEN commute_trips >= total_casual_trips_2024 * 0.4 
                THEN 'Commuter Station'
            WHEN total_casual_trips_2024 >= 1000 AND casual_percentage >= 70 
                THEN 'High-Volume Casual Hub'
            WHEN total_casual_trips_2024 BETWEEN 500 AND 1000 AND casual_percentage >= 60 
                THEN 'Medium-Volume Opportunity'
            WHEN total_casual_trips_2024 >= 200 AND usage_quality_score >= 60 
                THEN 'Quality Usage Station'
            ELSE 'Emerging Opportunity'
        END as station_type,
        
        -- Marketing investment recommendation
        CASE 
            WHEN (volume_opportunity_score * 0.4 + usage_quality_score * 0.3 + penetration_opportunity_score * 0.3) >= 85 
                THEN 'High Investment ($5,000-10,000/year)'
            WHEN (volume_opportunity_score * 0.4 + usage_quality_score * 0.3 + penetration_opportunity_score * 0.3) >= 75 
                THEN 'Medium Investment ($2,000-5,000/year)'
            WHEN (volume_opportunity_score * 0.4 + usage_quality_score * 0.3 + penetration_opportunity_score * 0.3) >= 65 
                THEN 'Low Investment ($500-2,000/year)'
            ELSE 'Minimal Investment ($100-500/year)'
        END as investment_recommendation,
        
        -- Specific marketing tactics
        CASE 
            WHEN weekend_trips > weekday_trips 
                THEN 'Weekend Events + Tourist-Focused Signage + Recreational Messaging'
            WHEN commute_trips >= total_casual_trips_2024 * 0.4 
                THEN 'Commuter Benefits + Rush Hour Promotions + Time-Saving Messaging'
            WHEN total_casual_trips_2024 >= 2000 
                THEN 'High-Visibility Displays + Street Teams + QR Code Campaigns'
            WHEN casual_percentage >= 70 
                THEN 'Conversion-Focused Signage + Member Benefits Display + Peer Influence'
            ELSE 'Community Partnerships + Local Events + Neighborhood Outreach'
        END as recommended_tactics,
        
        -- Expected conversion metrics
        ROUND(total_casual_trips_2024 * 0.15, 0) as conservative_conversion_target,  -- 15% conversion rate
        ROUND(total_casual_trips_2024 * 0.25, 0) as optimistic_conversion_target,   -- 25% conversion rate
        ROUND(total_casual_trips_2024 * 0.20 * {{ var('annual_membership_price') }}, 0) as annual_revenue_potential  -- 20% avg * membership price
        
    FROM station_opportunity_scoring
)

-- Main Results: Station-Based Marketing ROI Prioritization
SELECT 
    'STATION_ROI_ANALYSIS' as analysis_type,
    station_name,
    station_type,
    total_casual_trips_2024,
    unique_casual_riders,
    avg_trips_per_active_day,
    casual_percentage,
    composite_roi_score,
    investment_recommendation,
    recommended_tactics,
    conservative_conversion_target,
    optimistic_conversion_target,
    annual_revenue_potential,
    
    -- Campaign prioritization
    CASE 
        WHEN composite_roi_score >= 85 THEN 'Immediate Priority (Q1 2025)'
        WHEN composite_roi_score >= 75 THEN 'High Priority (Q1-Q2 2025)'
        WHEN composite_roi_score >= 65 THEN 'Medium Priority (Q2-Q3 2025)'
        ELSE 'Low Priority (Q3-Q4 2025)'
    END as campaign_timeline_priority,
    
    -- Success metrics
    CASE 
        WHEN composite_roi_score >= 85 THEN '20-30% conversion rate target'
        WHEN composite_roi_score >= 75 THEN '15-25% conversion rate target'
        WHEN composite_roi_score >= 65 THEN '10-20% conversion rate target'
        ELSE '5-15% conversion rate target'
    END as success_metrics_target

FROM roi_prioritization

ORDER BY composite_roi_score DESC, total_casual_trips_2024 DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

STATION PRIORITIZATION STRATEGY:
- Immediate Priority: High-volume tourist hubs and commuter stations with 85+ ROI scores
- High Priority: Medium-volume stations with strong conversion indicators  
- Medium Priority: Emerging opportunities with good usage quality
- Low Priority: Minimal volume stations for community-focused campaigns

INVESTMENT ALLOCATION:
- High Investment ($5K-10K): Top 20-30 stations with maximum ROI potential
- Medium Investment ($2K-5K): Secondary tier with solid conversion prospects
- Low Investment ($500-2K): Tactical opportunities and testing locations
- Minimal Investment ($100-500): Community presence and brand awareness

TACTICAL DEPLOYMENT:
- Tourist Hubs: Weekend events, recreational messaging, seasonal campaigns
- Commuter Stations: Rush hour promotions, time-saving benefits, consistency messaging
- High-Volume Casual: Conversion-focused displays, member benefits, social proof
- Emerging Opportunities: Community partnerships, local events, neighborhood outreach
*/
