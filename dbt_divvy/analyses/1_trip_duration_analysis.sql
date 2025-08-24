/*
BUSINESS QUESTION 1A: Trip Duration Distribution Analysis
=======================================================

INSIGHT OBJECTIVE:
Understand how casual riders vs annual members differ in trip duration patterns.
This reveals usage behavior differences that can inform membership conversion strategies.

MARKETING APPLICATION:
- Target casual riders who already take longer trips (likely recreational users)
- Develop messaging around convenience for regular commuters (short trips)
- Create membership packages that appeal to different duration preferences
- Identify "power users" among casual riders for premium membership targeting
*/

-- Trip Duration Distribution by User Type (2024 vs 2023 Comparison)
WITH duration_categories AS (
    SELECT 
        member_casual,
        EXTRACT(year FROM started_at) as trip_year,
        CASE 
            WHEN ride_length_minutes <= 10 THEN 'Short (≤10 min)'           -- Quick trips, likely commute
            WHEN ride_length_minutes <= 30 THEN 'Medium (10-30 min)'        -- Standard trips
            WHEN ride_length_minutes <= 60 THEN 'Long (30-60 min)'          -- Extended trips, likely recreational
            ELSE 'Extra Long (>60 min)'                                     -- Extended recreational/tourist
        END as duration_category,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration_minutes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ride_length_minutes) as median_duration_minutes
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440  -- Remove outliers (trips > 24 hours)
    GROUP BY member_casual, trip_year, duration_category
),
user_totals AS (
    SELECT 
        member_casual,
        trip_year,
        SUM(trip_count) as total_trips
    FROM duration_categories
    GROUP BY member_casual, trip_year
)

SELECT 
    dc.member_casual,
    dc.trip_year,
    dc.duration_category,
    dc.trip_count,
    ROUND(dc.trip_count * 100.0 / ut.total_trips, 2) as percentage_of_user_trips,
    ROUND(dc.avg_duration_minutes, 2) as avg_duration_minutes,
    ROUND(dc.median_duration_minutes, 2) as median_duration_minutes,
    -- Year-over-year growth calculation
    LAG(dc.trip_count) OVER (
        PARTITION BY dc.member_casual, dc.duration_category 
        ORDER BY dc.trip_year
    ) as previous_year_count,
    ROUND(
        (dc.trip_count - LAG(dc.trip_count) OVER (
            PARTITION BY dc.member_casual, dc.duration_category 
            ORDER BY dc.trip_year
        )) * 100.0 / NULLIF(LAG(dc.trip_count) OVER (
            PARTITION BY dc.member_casual, dc.duration_category 
            ORDER BY dc.trip_year
        ), 0), 
        2
    ) as yoy_growth_percentage
FROM duration_categories dc
JOIN user_totals ut ON dc.member_casual = ut.member_casual AND dc.trip_year = ut.trip_year
ORDER BY dc.member_casual, dc.trip_year, 
    CASE dc.duration_category 
        WHEN 'Short (≤10 min)' THEN 1
        WHEN 'Medium (10-30 min)' THEN 2 
        WHEN 'Long (30-60 min)' THEN 3
        ELSE 4
    END;

/*
EXPECTED INSIGHTS FOR MARKETING:
- Casual riders likely show higher percentage in "Long" and "Extra Long" categories (recreational use)
- Members likely dominate "Short" category (commute patterns)
- YoY growth patterns reveal which user segments are expanding
- Duration preferences can inform targeted membership pricing and messaging

KEY MARKETING ACTIONS:
1. Target casual riders in "Long" category with "unlimited rides" messaging
2. Focus on "Medium" duration casual riders with convenience/time-saving benefits
3. Create tiered membership plans based on duration preferences
4. Develop seasonal campaigns based on YoY growth patterns
*/
