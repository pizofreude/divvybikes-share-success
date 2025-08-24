/*
BUSINESS QUESTION 2C: Temporal Patterns and Conversion Timeline Analysis
=======================================================================

INSIGHT OBJECTIVE:
Analyze how long casual riders typically use the service before showing conversion
readiness signals. Identify temporal patterns that indicate optimal conversion timing.

MARKETING APPLICATION:
- Determine optimal timing for conversion campaign outreach
- Identify lifecycle stages for progressive nurturing campaigns
- Design triggered messaging based on usage tenure and growth patterns
- Predict conversion windows based on usage evolution
*/

-- Temporal Usage Evolution and Conversion Timing Analysis (2024 Focus)
WITH casual_rider_timeline AS (
    -- Track casual rider usage evolution over time
    SELECT 
        CASE 
            WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
            ELSE start_station_name 
        END as primary_station,
        DATE(started_at) as trip_date,
        DATE_TRUNC('month', started_at) as usage_month,
        DATE_TRUNC('week', started_at) as usage_week,
        COUNT(*) as daily_trips,
        AVG(ride_length_minutes) as daily_avg_duration,
        -- Calculate running usage metrics
        SUM(COUNT(*)) OVER (
            PARTITION BY primary_station 
            ORDER BY DATE(started_at) 
            ROWS UNBOUNDED PRECEDING
        ) as cumulative_trips,
        -- Days since first usage
        DATE(started_at) - MIN(DATE(started_at)) OVER (
            PARTITION BY primary_station
        ) as days_since_first_trip,
        -- Usage intensity indicators
        CASE 
            WHEN COUNT(*) >= 3 THEN 'High Daily Usage (3+ trips)'
            WHEN COUNT(*) = 2 THEN 'Medium Daily Usage (2 trips)'
            ELSE 'Low Daily Usage (1 trip)'
        END as daily_usage_intensity
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        CASE 
            WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
            ELSE start_station_name 
        END, 
        DATE(started_at),
        DATE_TRUNC('month', started_at),
        DATE_TRUNC('week', started_at)
),
usage_maturity_stages AS (
    -- Define usage maturity stages based on cumulative experience
    SELECT 
        primary_station,
        trip_date,
        usage_month,
        usage_week,
        daily_trips,
        cumulative_trips,
        days_since_first_trip,
        daily_usage_intensity,
        -- Define lifecycle stages
        CASE 
            WHEN days_since_first_trip <= 7 THEN 'New User (0-7 days)'
            WHEN days_since_first_trip <= 30 THEN 'Trial User (8-30 days)'
            WHEN days_since_first_trip <= 90 THEN 'Regular User (31-90 days)'
            WHEN days_since_first_trip <= 180 THEN 'Established User (91-180 days)'
            ELSE 'Veteran User (180+ days)'
        END as user_lifecycle_stage,
        -- Usage frequency evolution
        CASE 
            WHEN cumulative_trips <= 5 THEN 'Exploration Phase (1-5 trips)'
            WHEN cumulative_trips <= 15 THEN 'Adoption Phase (6-15 trips)'
            WHEN cumulative_trips <= 30 THEN 'Habit Formation (16-30 trips)'
            WHEN cumulative_trips <= 60 THEN 'Regular Usage (31-60 trips)'
            ELSE 'Power User (60+ trips)'
        END as usage_evolution_stage,
        -- Conversion readiness indicators
        CASE 
            WHEN cumulative_trips >= 20 AND days_since_first_trip >= 60 THEN 'High Conversion Readiness'
            WHEN cumulative_trips >= 15 AND days_since_first_trip >= 30 THEN 'Medium Conversion Readiness'
            WHEN cumulative_trips >= 10 AND days_since_first_trip >= 14 THEN 'Low Conversion Readiness'
            ELSE 'Not Ready for Conversion'
        END as conversion_readiness_stage
    FROM casual_rider_timeline
),
monthly_progression_analysis AS (
    -- Analyze month-over-month usage progression patterns
    SELECT 
        primary_station,
        usage_month,
        COUNT(*) as monthly_trip_days,
        SUM(daily_trips) as monthly_total_trips,
        AVG(daily_trips) as avg_daily_trips,
        MAX(cumulative_trips) as month_end_cumulative_trips,
        MAX(days_since_first_trip) as month_end_tenure_days,
        -- Calculate monthly growth
        LAG(SUM(daily_trips)) OVER (
            PARTITION BY primary_station 
            ORDER BY usage_month
        ) as previous_month_trips,
        ROUND(
            (SUM(daily_trips) - LAG(SUM(daily_trips)) OVER (
                PARTITION BY primary_station 
                ORDER BY usage_month
            )) * 100.0 / NULLIF(LAG(SUM(daily_trips)) OVER (
                PARTITION BY primary_station 
                ORDER BY usage_month
            ), 0), 2
        ) as monthly_growth_percentage,
        -- Identify conversion-ready months
        COUNT(CASE WHEN conversion_readiness_stage = 'High Conversion Readiness' THEN 1 END) as high_readiness_days,
        COUNT(CASE WHEN conversion_readiness_stage = 'Medium Conversion Readiness' THEN 1 END) as medium_readiness_days
    FROM usage_maturity_stages
    GROUP BY primary_station, usage_month
),
conversion_timing_patterns AS (
    -- Identify optimal conversion timing patterns
    SELECT 
        user_lifecycle_stage,
        usage_evolution_stage,
        conversion_readiness_stage,
        COUNT(DISTINCT primary_station) as unique_casual_riders,
        COUNT(*) as total_user_days,
        ROUND(AVG(cumulative_trips), 2) as avg_cumulative_trips,
        ROUND(AVG(days_since_first_trip), 2) as avg_tenure_days,
        ROUND(AVG(daily_trips), 2) as avg_daily_trips,
        -- Conversion timing recommendations
        CASE 
            WHEN conversion_readiness_stage = 'High Conversion Readiness' THEN 'Immediate Outreach Recommended'
            WHEN conversion_readiness_stage = 'Medium Conversion Readiness' THEN 'Nurture for 2-4 weeks'
            WHEN conversion_readiness_stage = 'Low Conversion Readiness' THEN 'Educational Content Phase'
            ELSE 'Awareness Building Phase'
        END as recommended_marketing_action,
        -- Optimal messaging timing
        CASE 
            WHEN user_lifecycle_stage = 'New User (0-7 days)' THEN 'Welcome & Education'
            WHEN user_lifecycle_stage = 'Trial User (8-30 days)' THEN 'Value Demonstration'
            WHEN user_lifecycle_stage = 'Regular User (31-90 days)' THEN 'Conversion Opportunity'
            WHEN user_lifecycle_stage = 'Established User (91-180 days)' THEN 'Loyalty & Savings Focus'
            ELSE 'Retention & Upgrade Focus'
        END as messaging_phase
    FROM usage_maturity_stages
    GROUP BY user_lifecycle_stage, usage_evolution_stage, conversion_readiness_stage
),
optimal_conversion_windows AS (
    -- Identify specific timing windows with highest conversion potential
    SELECT 
        'OPTIMAL_TIMING_ANALYSIS' as analysis_type,
        (user_lifecycle_stage || ' + ' || usage_evolution_stage) as timing_combination,
        conversion_readiness_stage,
        unique_casual_riders,
        avg_cumulative_trips,
        avg_tenure_days,
        recommended_marketing_action,
        messaging_phase,
        -- Priority scoring for marketing campaigns
        CASE 
            WHEN conversion_readiness_stage = 'High Conversion Readiness' AND unique_casual_riders > 50 THEN 95
            WHEN conversion_readiness_stage = 'High Conversion Readiness' AND unique_casual_riders > 20 THEN 85
            WHEN conversion_readiness_stage = 'Medium Conversion Readiness' AND unique_casual_riders > 100 THEN 75
            WHEN conversion_readiness_stage = 'Medium Conversion Readiness' AND unique_casual_riders > 50 THEN 65
            ELSE 45
        END as campaign_priority_score,
        -- Estimated conversion rate based on readiness and timing
        CASE 
            WHEN conversion_readiness_stage = 'High Conversion Readiness' 
                AND user_lifecycle_stage LIKE '%Regular User%' THEN '25-35%'
            WHEN conversion_readiness_stage = 'High Conversion Readiness' 
                AND user_lifecycle_stage LIKE '%Established User%' THEN '30-40%'
            WHEN conversion_readiness_stage = 'Medium Conversion Readiness' 
                AND user_lifecycle_stage LIKE '%Regular User%' THEN '15-25%'
            WHEN conversion_readiness_stage = 'Medium Conversion Readiness' 
                AND user_lifecycle_stage LIKE '%Established User%' THEN '20-30%'
            ELSE '5-15%'
        END as estimated_conversion_rate
    FROM conversion_timing_patterns
    WHERE unique_casual_riders >= 10  -- Focus on meaningful segments
)

-- Main Results: Temporal Conversion Analysis
SELECT 
    analysis_type,
    timing_combination,
    conversion_readiness_stage,
    unique_casual_riders,
    avg_cumulative_trips,
    avg_tenure_days,
    recommended_marketing_action,
    messaging_phase,
    campaign_priority_score,
    estimated_conversion_rate,
    -- Additional campaign insights
    CASE 
        WHEN avg_tenure_days BETWEEN 60 AND 120 AND avg_cumulative_trips >= 20 THEN 'Peak Conversion Window'
        WHEN avg_tenure_days BETWEEN 30 AND 90 AND avg_cumulative_trips >= 15 THEN 'Prime Nurturing Window'
        WHEN avg_tenure_days <= 30 AND avg_cumulative_trips >= 10 THEN 'Early Engagement Window'
        ELSE 'Standard Timeline'
    END as conversion_window_type
FROM optimal_conversion_windows

UNION ALL

-- Monthly Growth Trend Analysis for High-Potential Users
SELECT 
    'GROWTH_TREND_ANALYSIS' as analysis_type,
    CASE 
        WHEN monthly_growth_percentage > 50 THEN 'Accelerating Growth (50%+ MoM)'
        WHEN monthly_growth_percentage > 25 THEN 'Strong Growth (25-50% MoM)'
        WHEN monthly_growth_percentage > 0 THEN 'Moderate Growth (0-25% MoM)'
        WHEN monthly_growth_percentage > -25 THEN 'Stable Usage (-25 to 0% MoM)'
        ELSE 'Declining Usage (<-25% MoM)'
    END as timing_combination,
    'Growth Pattern Analysis' as conversion_readiness_stage,
    COUNT(DISTINCT primary_station) as unique_casual_riders,
    ROUND(AVG(monthly_total_trips), 2) as avg_cumulative_trips,
    ROUND(AVG(month_end_tenure_days), 2) as avg_tenure_days,
    CASE 
        WHEN AVG(monthly_growth_percentage) > 25 THEN 'Immediate Conversion Push'
        WHEN AVG(monthly_growth_percentage) > 0 THEN 'Capitalize on Growth'
        ELSE 'Re-engagement Strategy'
    END as recommended_marketing_action,
    'Growth-Based Messaging' as messaging_phase,
    CASE 
        WHEN AVG(monthly_growth_percentage) > 50 THEN 90
        WHEN AVG(monthly_growth_percentage) > 25 THEN 80
        WHEN AVG(monthly_growth_percentage) > 0 THEN 60
        ELSE 30
    END as campaign_priority_score,
    CASE 
        WHEN AVG(monthly_growth_percentage) > 50 THEN '35-45%'
        WHEN AVG(monthly_growth_percentage) > 25 THEN '25-35%'
        WHEN AVG(monthly_growth_percentage) > 0 THEN '15-25%'
        ELSE '5-15%'
    END as estimated_conversion_rate,
    'Momentum-Based Timing' as conversion_window_type
FROM monthly_progression_analysis
WHERE monthly_growth_percentage IS NOT NULL
    AND month_end_cumulative_trips >= 10
GROUP BY 
    CASE 
        WHEN monthly_growth_percentage > 50 THEN 'Accelerating Growth (50%+ MoM)'
        WHEN monthly_growth_percentage > 25 THEN 'Strong Growth (25-50% MoM)'
        WHEN monthly_growth_percentage > 0 THEN 'Moderate Growth (0-25% MoM)'
        WHEN monthly_growth_percentage > -25 THEN 'Stable Usage (-25 to 0% MoM)'
        ELSE 'Declining Usage (<-25% MoM)'
    END

ORDER BY campaign_priority_score DESC, unique_casual_riders DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

OPTIMAL CONVERSION TIMING:
- Peak Window: 60-120 days tenure with 20+ cumulative trips
- Prime Opportunity: Regular Users (31-90 days) in Habit Formation stage
- Early Signals: 15+ trips within first 30 days indicates high potential
- Growth Momentum: 25%+ month-over-month growth = immediate action

LIFECYCLE-BASED MESSAGING:
- New Users (0-7 days): Welcome, education, first-trip incentives
- Trial Users (8-30 days): Value demonstration, convenience benefits
- Regular Users (31-90 days): Conversion campaigns, savings messaging
- Established Users (91-180 days): Loyalty focus, annual membership value
- Veteran Users (180+ days): Retention, upgrade opportunities

CAMPAIGN TRIGGER POINTS:
- 20+ trips reached: High-priority conversion campaign
- 60+ days tenure: Financial benefits messaging
- Month-over-month growth >25%: Momentum-based conversion push
- 30+ cumulative trips: Premium membership tier consideration

KEY MARKETING ACTIONS:
1. **Lifecycle Email Series**: Automated campaigns based on tenure stages
2. **Usage Milestone Triggers**: Celebrate trip milestones with conversion offers
3. **Growth Momentum Campaigns**: Target users showing increasing usage
4. **Timing Optimization**: Launch conversion campaigns at optimal windows
5. **Progressive Nurturing**: Graduated messaging intensity based on readiness stage
*/
