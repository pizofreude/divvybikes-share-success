/*
BUSINESS QUESTION 2A: Usage Frequency Thresholds for Financial Conversion
========================================================================

INSIGHT OBJECTIVE:
Identify usage frequency and cost thresholds that make membership financially beneficial
for casual riders. Calculate break-even points and cost analysis.

MARKETING APPLICATION:
- Develop personalized membership value propositions based on current usage
- Create usage-based discount strategies for high-frequency casual riders
- Design trial membership offers based on usage patterns
- Implement dynamic pricing strategies for conversion
*/

-- Usage Frequency and Financial Analysis (2024 Focus)
WITH casual_rider_metrics AS (
    SELECT 
        CASE 
            WHEN start_station_name IS NULL OR start_station_name = '' THEN 'Unknown Station'
            ELSE start_station_name 
        END as station_name,
        DATE_TRUNC('month', started_at) as usage_month,
        COUNT(*) as monthly_trips,
        AVG(ride_length_minutes) as avg_duration_minutes,
        SUM(ride_length_minutes) as total_duration_minutes,
        -- Calculate casual cost based on current pricing
        SUM(
            CASE 
                WHEN rideable_type = 'ELECTRIC_BIKE' THEN 
                    1.00 + (GREATEST(ride_length_minutes - 30, 0) * 0.25) -- $1 unlock + $0.25/min after 30min
                ELSE 
                    1.00 + (GREATEST(ride_length_minutes - 30, 0) * 0.15) -- $1 unlock + $0.15/min after 30min
            END
        ) as monthly_casual_cost,
        -- Membership would cost $15/month
        15.00 as monthly_membership_cost,
        -- Calculate savings if member
        SUM(
            CASE 
                WHEN rideable_type = 'ELECTRIC_BIKE' THEN 
                    1.00 + (GREATEST(ride_length_minutes - 30, 0) * 0.25)
                ELSE 
                    1.00 + (GREATEST(ride_length_minutes - 30, 0) * 0.15)
            END
        ) - 15.00 as potential_monthly_savings
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY station_name, DATE_TRUNC('month', started_at)
),
usage_frequency_segments AS (
    -- Segment casual riders by monthly usage frequency
    SELECT 
        station_name,
        usage_month,
        monthly_trips,
        avg_duration_minutes,
        monthly_casual_cost,
        monthly_membership_cost,
        potential_monthly_savings,
        CASE 
            WHEN monthly_trips >= 20 THEN 'Super Heavy User (20+ trips/month)'
            WHEN monthly_trips >= 15 THEN 'Heavy User (15-19 trips/month)'
            WHEN monthly_trips >= 10 THEN 'Moderate User (10-14 trips/month)'
            WHEN monthly_trips >= 5 THEN 'Light User (5-9 trips/month)'
            ELSE 'Occasional User (<5 trips/month)'
        END as usage_frequency_category,
        CASE 
            WHEN potential_monthly_savings > 10 THEN 'High Savings Potential (>$10/month)'
            WHEN potential_monthly_savings > 5 THEN 'Medium Savings Potential ($5-10/month)'
            WHEN potential_monthly_savings > 0 THEN 'Low Savings Potential ($0-5/month)'
            ELSE 'No Financial Benefit'
        END as savings_category,
        -- Calculate conversion likelihood based on financial benefit
        CASE 
            WHEN potential_monthly_savings > 15 AND monthly_trips >= 15 THEN 95
            WHEN potential_monthly_savings > 10 AND monthly_trips >= 12 THEN 85
            WHEN potential_monthly_savings > 5 AND monthly_trips >= 8 THEN 70
            WHEN potential_monthly_savings > 0 AND monthly_trips >= 5 THEN 50
            ELSE 25
        END as financial_conversion_score
    FROM casual_rider_metrics
),
annual_projection AS (
    -- Project annual usage and savings for consistent users
    SELECT 
        station_name,
        usage_frequency_category,
        savings_category,
        COUNT(*) as months_active,
        AVG(monthly_trips) as avg_monthly_trips,
        AVG(monthly_casual_cost) as avg_monthly_casual_cost,
        AVG(potential_monthly_savings) as avg_monthly_savings,
        AVG(financial_conversion_score) as avg_conversion_score,
        -- Annual projections
        AVG(monthly_trips) * 12 as projected_annual_trips,
        AVG(monthly_casual_cost) * 12 as projected_annual_casual_cost,
        180.00 as annual_membership_cost, -- $15 * 12 months
        (AVG(monthly_casual_cost) * 12) - 180.00 as projected_annual_savings,
        -- Consistency score (more months = more reliable conversion target)
        ROUND(COUNT(*) * 100.0 / 12, 2) as usage_consistency_percentage
    FROM usage_frequency_segments
    GROUP BY station_name, usage_frequency_category, savings_category
),
break_even_analysis AS (
    -- Calculate break-even points for membership conversion
    SELECT 
        'BREAK_EVEN_ANALYSIS' as analysis_type,
        usage_frequency_category,
        savings_category,
        COUNT(*) as user_segments_count,
        ROUND(AVG(avg_monthly_trips), 2) as avg_monthly_trips,
        ROUND(AVG(projected_annual_trips), 2) as avg_annual_trips,
        ROUND(AVG(projected_annual_casual_cost), 2) as avg_annual_casual_cost,
        180.00 as annual_membership_cost,
        ROUND(AVG(projected_annual_savings), 2) as avg_annual_savings,
        ROUND(AVG(avg_conversion_score), 2) as avg_conversion_score,
        ROUND(AVG(usage_consistency_percentage), 2) as consistency_score,
        -- Marketing priority based on savings and volume
        CASE 
            WHEN AVG(projected_annual_savings) > 100 AND COUNT(*) > 50 THEN 'Immediate Priority'
            WHEN AVG(projected_annual_savings) > 50 AND COUNT(*) > 25 THEN 'High Priority'
            WHEN AVG(projected_annual_savings) > 20 AND COUNT(*) > 10 THEN 'Medium Priority'
            ELSE 'Low Priority'
        END as marketing_priority
    FROM annual_projection
    WHERE months_active >= 3  -- Focus on consistent users
    GROUP BY usage_frequency_category, savings_category
)

-- Main Results: Financial Conversion Analysis
SELECT 
    analysis_type,
    usage_frequency_category,
    savings_category,
    user_segments_count,
    avg_monthly_trips,
    avg_annual_trips,
    avg_annual_casual_cost,
    annual_membership_cost,
    avg_annual_savings,
    avg_conversion_score,
    consistency_score,
    marketing_priority,
    -- Additional insights for messaging
    CASE 
        WHEN avg_annual_savings > 200 THEN 'Premium Value Message: Save $' || ROUND(avg_annual_savings, 0) || '/year'
        WHEN avg_annual_savings > 100 THEN 'High Value Message: Save $' || ROUND(avg_annual_savings, 0) || '/year'
        WHEN avg_annual_savings > 50 THEN 'Medium Value Message: Save $' || ROUND(avg_annual_savings, 0) || '/year'
        ELSE 'Lifestyle Message: Focus on convenience, not savings'
    END as recommended_messaging,
    -- Break-even trip calculation
    ROUND(180.0 / (avg_annual_casual_cost / avg_annual_trips), 0) as break_even_annual_trips
FROM break_even_analysis

UNION ALL

-- Station-Level High-Value Conversion Targets
SELECT 
    'STATION_CONVERSION_TARGETS' as analysis_type,
    ap.usage_frequency_category,
    ap.savings_category,
    1 as user_segments_count,
    ap.avg_monthly_trips,
    ap.projected_annual_trips as avg_annual_trips,
    ap.projected_annual_casual_cost as avg_annual_casual_cost,
    ap.annual_membership_cost,
    ap.projected_annual_savings as avg_annual_savings,
    ap.avg_conversion_score,
    ap.usage_consistency_percentage as consistency_score,
    CASE 
        WHEN ap.projected_annual_savings > 150 AND ap.usage_consistency_percentage > 75 THEN 'Immediate Priority'
        WHEN ap.projected_annual_savings > 75 AND ap.usage_consistency_percentage > 50 THEN 'High Priority'
        ELSE 'Medium Priority'
    END as marketing_priority,
    ap.station_name as recommended_messaging,
    ROUND(180.0 / (ap.projected_annual_casual_cost / ap.projected_annual_trips), 0) as break_even_annual_trips
FROM annual_projection ap
WHERE ap.projected_annual_savings > 50  -- Focus on financially beneficial conversions
    AND ap.usage_consistency_percentage > 40  -- Consistent users only
    AND ap.months_active >= 6  -- At least 6 months of data

ORDER BY 
    analysis_type,
    avg_annual_savings DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

FINANCIAL THRESHOLDS:
- Break-even point: ~12-15 trips per month for typical casual riders
- High-value targets: 20+ trips/month with potential savings >$100/year
- Sweet spot: 15-19 trips/month with consistent 6+ month usage patterns

MESSAGING STRATEGIES:
- Premium users (>$200 savings): Lead with financial benefits
- Medium users ($50-200 savings): Balance convenience and savings
- Light users (<$50 savings): Focus on lifestyle and convenience benefits

CONVERSION TIMING:
- Target users after 3+ months of consistent usage
- Focus on users with 75%+ monthly consistency
- Prioritize those already spending $20+ per month

KEY MARKETING ACTIONS:
1. **Personalized Cost Analysis**: Show individual savings potential
2. **Trial Membership**: Offer 1-month trials to 15+ trip users
3. **Usage-Based Discounts**: Graduated membership pricing for power users
4. **Timing Campaigns**: Target after 3 months of consistent high usage
5. **Station-Specific Offers**: Focus on high-usage stations with savings potential
*/
