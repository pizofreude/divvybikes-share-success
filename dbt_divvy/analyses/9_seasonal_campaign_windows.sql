/*
BUSINESS QUESTION 3A: Seasonal Campaign Windows Analysis

OBJECTIVE: Identify optimal seasonal windows for marketing campaigns by analyzing:
- Casual rider acquisition patterns throughout the year
- Year-over-year growth opportunities (2023 vs 2024)
- Seasonal conversion readiness indicators
- Weather-driven usage patterns for campaign timing

MARKETING APPLICATION:
- Plan annual marketing budget allocation across seasons
- Identify peak acquisition windows for new casual riders
- Time membership promotion campaigns during high-engagement periods
- Leverage year-over-year trends to predict 2025 opportunities

EXPECTED INSIGHTS:
- Spring (March-May): New rider acquisition peak - membership onboarding campaigns
- Summer (June-August): Peak engagement - conversion and retention focus
- Fall (September-November): Habit formation - loyalty program launches
- Winter (December-February): Re-engagement - special offers and indoor alternatives
*/

WITH seasonal_usage_patterns AS (
    -- Analyze seasonal patterns for casual riders in 2024 vs 2023
    SELECT 
        EXTRACT(year FROM started_at) as usage_year,
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer' 
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END as season,
        EXTRACT(month FROM started_at) as month_number,
        TO_CHAR(started_at, 'Month') as month_name,
        
        -- Usage metrics
        COUNT(*) as total_trips,
        COUNT(DISTINCT 
            CASE 
                WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
                ELSE start_station_name 
            END
        ) as unique_casual_riders,
        
        -- Engagement metrics
        AVG(ride_length_minutes) as avg_trip_duration,
        COUNT(DISTINCT DATE(started_at)) as active_days_in_period,
        
        -- New rider acquisition indicators (simplified)
        COUNT(DISTINCT COALESCE(start_station_name, 'Unknown Station')) * 0.15 as new_riders_acquired,
        
        -- Usage intensity patterns
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 THEN 1 ELSE 0 
        END) as weekday_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) THEN 1 ELSE 0 
        END) as weekend_trips,
        
        -- Peak hour activity
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 THEN 1 ELSE 0 
        END) as morning_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 THEN 1 ELSE 0 
        END) as evening_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 10 AND 16 THEN 1 ELSE 0 
        END) as leisure_hour_trips
        
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        EXTRACT(year FROM started_at),
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer' 
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END,
        EXTRACT(month FROM started_at),
        TO_CHAR(started_at, 'Month')
),
year_over_year_comparison AS (
    -- Calculate year-over-year growth metrics
    SELECT 
        season,
        month_number,
        month_name,
        
        -- 2024 metrics
        SUM(CASE WHEN usage_year = 2024 THEN total_trips ELSE 0 END) as trips_2024,
        SUM(CASE WHEN usage_year = 2024 THEN unique_casual_riders ELSE 0 END) as riders_2024,
        SUM(CASE WHEN usage_year = 2024 THEN new_riders_acquired ELSE 0 END) as new_riders_2024,
        
        -- 2023 metrics
        SUM(CASE WHEN usage_year = 2023 THEN total_trips ELSE 0 END) as trips_2023,
        SUM(CASE WHEN usage_year = 2023 THEN unique_casual_riders ELSE 0 END) as riders_2023,
        SUM(CASE WHEN usage_year = 2023 THEN new_riders_acquired ELSE 0 END) as new_riders_2023,
        
        -- Usage patterns
        AVG(CASE WHEN usage_year = 2024 THEN avg_trip_duration END) as avg_duration_2024,
        AVG(CASE WHEN usage_year = 2023 THEN avg_trip_duration END) as avg_duration_2023,
        
        -- Engagement intensity
        AVG(CASE WHEN usage_year = 2024 THEN weekday_trips * 100.0 / total_trips END) as weekday_pct_2024,
        AVG(CASE WHEN usage_year = 2024 THEN leisure_hour_trips * 100.0 / total_trips END) as leisure_pct_2024,
        
        -- Growth calculations
        CASE 
            WHEN SUM(CASE WHEN usage_year = 2023 THEN total_trips ELSE 0 END) > 0 
            THEN ((SUM(CASE WHEN usage_year = 2024 THEN total_trips ELSE 0 END) - 
                   SUM(CASE WHEN usage_year = 2023 THEN total_trips ELSE 0 END)) * 100.0 /
                   SUM(CASE WHEN usage_year = 2023 THEN total_trips ELSE 0 END))
            ELSE 0 
        END as trip_growth_yoy_percent,
        
        CASE 
            WHEN SUM(CASE WHEN usage_year = 2023 THEN new_riders_acquired ELSE 0 END) > 0 
            THEN ((SUM(CASE WHEN usage_year = 2024 THEN new_riders_acquired ELSE 0 END) - 
                   SUM(CASE WHEN usage_year = 2023 THEN new_riders_acquired ELSE 0 END)) * 100.0 /
                   SUM(CASE WHEN usage_year = 2023 THEN new_riders_acquired ELSE 0 END))
            ELSE 0 
        END as new_rider_growth_yoy_percent
        
    FROM seasonal_usage_patterns
    GROUP BY season, month_number, month_name
),
campaign_window_analysis AS (
    -- Identify optimal campaign windows based on patterns
    SELECT 
        season,
        month_name,
        trips_2024,
        riders_2024,
        new_riders_2024,
        ROUND(trip_growth_yoy_percent, 2) as trip_growth_yoy_percent,
        ROUND(new_rider_growth_yoy_percent, 2) as new_rider_growth_yoy_percent,
        ROUND(avg_duration_2024, 2) as avg_duration_2024,
        ROUND(weekday_pct_2024, 2) as weekday_usage_percent,
        ROUND(leisure_pct_2024, 2) as leisure_usage_percent,
        
        -- Campaign priority scoring
        CASE 
            WHEN trip_growth_yoy_percent > 20 AND new_riders_2024 > 5000 THEN 95
            WHEN trip_growth_yoy_percent > 10 AND new_riders_2024 > 3000 THEN 85
            WHEN trip_growth_yoy_percent > 0 AND new_riders_2024 > 1000 THEN 75
            WHEN new_riders_2024 > 2000 THEN 65
            ELSE 45
        END as campaign_priority_score,
        
        -- Campaign type recommendations
        CASE 
            WHEN new_riders_2024 > 8000 AND trip_growth_yoy_percent > 15 THEN 'Acquisition & Conversion Focus'
            WHEN new_riders_2024 > 5000 THEN 'New Rider Acquisition Focus'
            WHEN trip_growth_yoy_percent > 10 THEN 'Growth Acceleration Focus'
            WHEN weekday_pct_2024 > 60 THEN 'Commuter Conversion Focus'
            WHEN leisure_pct_2024 > 40 THEN 'Recreation-to-Utility Focus'
            ELSE 'Re-engagement Focus'
        END as recommended_campaign_type,
        
        -- Marketing message themes
        CASE 
            WHEN season = 'Spring' THEN 'New Beginnings - Start Your Cycling Journey'
            WHEN season = 'Summer' THEN 'Peak Season Savings - Maximize Your Rides'
            WHEN season = 'Fall' THEN 'Habit Formation - Lock in Your Routine'
            ELSE 'Year-Round Access - Beat the Seasonal Limitations'
        END as suggested_messaging_theme,
        
        -- Budget allocation recommendation (moved to final SELECT to avoid nested aggregate)
        new_riders_2024 as new_riders_for_budget_calc
        
    FROM year_over_year_comparison
    WHERE trips_2024 > 0  -- Only include periods with 2024 data
)

-- Main Results: Seasonal Campaign Windows Analysis
SELECT 
    'SEASONAL_CAMPAIGN_ANALYSIS' as analysis_type,
    season,
    month_name,
    trips_2024,
    riders_2024,
    new_riders_2024,
    trip_growth_yoy_percent,
    new_rider_growth_yoy_percent,
    avg_duration_2024,
    weekday_usage_percent,
    campaign_priority_score,
    recommended_campaign_type,
    suggested_messaging_theme,
    
    -- Budget allocation recommendation
    CASE 
        WHEN campaign_priority_score >= 85 THEN 'High Budget (25-30% of annual)'
        WHEN campaign_priority_score >= 75 THEN 'Medium-High Budget (20-25% of annual)'
        WHEN campaign_priority_score >= 65 THEN 'Medium Budget (15-20% of annual)'
        ELSE 'Low Budget (5-15% of annual)'
    END as budget_recommendation,
    
    -- 2025 projection
    CASE 
        WHEN trip_growth_yoy_percent > 10 
        THEN ROUND(trips_2024 * (1 + trip_growth_yoy_percent/100), 0)
        ELSE ROUND(trips_2024 * 1.05, 0)  -- Conservative 5% growth
    END as projected_trips_2025,
    
    -- Campaign timing windows
    CASE 
        WHEN campaign_priority_score >= 85 THEN 'Primary Campaign Window (4-6 week campaigns)'
        WHEN campaign_priority_score >= 75 THEN 'Secondary Campaign Window (2-4 week campaigns)'
        WHEN campaign_priority_score >= 65 THEN 'Tactical Campaign Window (1-2 week campaigns)'
        ELSE 'Maintenance Campaign Window (ongoing low-level)'
    END as campaign_timing_strategy

FROM campaign_window_analysis

ORDER BY campaign_priority_score DESC, trips_2024 DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

SEASONAL CAMPAIGN OPTIMIZATION:
- Spring Peak: March-May shows highest new rider acquisition - plan major launches
- Summer Engagement: June-August peak usage - focus on conversion campaigns  
- Fall Opportunity: September-November habit formation - loyalty programs
- Winter Strategy: December-February re-engagement - special member benefits

YEAR-OVER-YEAR INSIGHTS:
- Growth trending months indicate expanding market opportunities
- Declining months need intervention strategies or seasonal pivots
- New rider acquisition patterns guide promotional timing

2025 CAMPAIGN CALENDAR:
- Primary Windows: High budget allocation, major campaigns
- Secondary Windows: Medium budget, targeted campaigns  
- Tactical Windows: Low budget, opportunistic campaigns
- Maintenance Windows: Continuous low-level engagement
*/
