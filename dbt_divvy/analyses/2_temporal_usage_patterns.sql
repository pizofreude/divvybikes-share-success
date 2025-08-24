/*
BUSINESS QUESTION 1B: Weekly and Daily Usage Pattern Analysis
===========================================================

INSIGHT OBJECTIVE:
Identify temporal usage patterns to understand when casual riders vs members use the service.
This reveals lifestyle and commute patterns that inform targeted marketing timing.

MARKETING APPLICATION:
- Time-targeted digital advertising campaigns
- Develop "trial membership" offers during casual rider peak times
- Create commuter-focused messaging for weekday patterns
- Design weekend recreational membership packages
*/

-- Weekly and Daily Usage Patterns (2024 Focus with 2023 Comparison)
WITH daily_patterns AS (
    SELECT 
        member_casual,
        EXTRACT(year FROM started_at) as trip_year,
        EXTRACT(dow FROM started_at) as day_of_week,  -- 0=Sunday, 6=Saturday
        CASE 
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END as day_type,
        CASE EXTRACT(dow FROM started_at)
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday' 
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END as day_name,
        EXTRACT(hour FROM started_at) as trip_hour,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration_minutes
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, 
             EXTRACT(year FROM started_at),
             EXTRACT(dow FROM started_at),
             CASE 
                 WHEN EXTRACT(dow FROM started_at) IN (0, 6) THEN 'Weekend'
                 ELSE 'Weekday'
             END,
             CASE EXTRACT(dow FROM started_at)
                 WHEN 0 THEN 'Sunday'
                 WHEN 1 THEN 'Monday' 
                 WHEN 2 THEN 'Tuesday'
                 WHEN 3 THEN 'Wednesday'
                 WHEN 4 THEN 'Thursday'
                 WHEN 5 THEN 'Friday'
                 WHEN 6 THEN 'Saturday'
             END,
             EXTRACT(hour FROM started_at)
),
hourly_summary AS (
    SELECT 
        member_casual,
        trip_year,
        day_type,
        trip_hour,
        SUM(trip_count) as total_trips,
        AVG(avg_duration_minutes) as avg_duration
    FROM daily_patterns
    GROUP BY member_casual, trip_year, day_type, trip_hour
),
daily_summary AS (
    SELECT 
        member_casual,
        trip_year,
        day_name,
        day_type,
        SUM(trip_count) as total_daily_trips,
        AVG(avg_duration_minutes) as avg_daily_duration
    FROM daily_patterns
    GROUP BY member_casual, trip_year, day_name, day_type, day_of_week
    ORDER BY day_of_week
)

-- Main Query: Combined Daily and Peak Hour Analysis
SELECT 
    'DAILY_SUMMARY' as analysis_type,
    ds.member_casual,
    ds.trip_year,
    ds.day_name,
    ds.day_type,
    ds.total_daily_trips,
    ROUND(ds.avg_daily_duration, 2) as avg_duration_minutes,
    -- Calculate percentage of weekly trips
    ROUND(
        ds.total_daily_trips * 100.0 / SUM(ds.total_daily_trips) OVER (
            PARTITION BY ds.member_casual, ds.trip_year
        ), 2
    ) as pct_of_weekly_trips,
    NULL as trip_hour,
    NULL as hour_rank,
    -- YoY comparison
    LAG(ds.total_daily_trips) OVER (
        PARTITION BY ds.member_casual, ds.day_name 
        ORDER BY ds.trip_year
    ) as previous_year_trips,
    ROUND(
        (ds.total_daily_trips - LAG(ds.total_daily_trips) OVER (
            PARTITION BY ds.member_casual, ds.day_name 
            ORDER BY ds.trip_year
        )) * 100.0 / NULLIF(LAG(ds.total_daily_trips) OVER (
            PARTITION BY ds.member_casual, ds.day_name 
            ORDER BY ds.trip_year
        ), 0), 2
    ) as yoy_growth_pct
FROM daily_summary ds

UNION ALL

-- Peak Hours Analysis (Top 3 hours per user type per day type)
SELECT 
    'PEAK_HOURS' as analysis_type,
    ranked_hours.member_casual,
    ranked_hours.trip_year,
    ranked_hours.day_type as day_name,
    ranked_hours.day_type,
    ranked_hours.total_trips as total_daily_trips,
    ROUND(ranked_hours.avg_duration, 2) as avg_duration_minutes,
    -- Rank within day type
    NULL as pct_of_weekly_trips,
    ranked_hours.trip_hour,
    ranked_hours.hour_rank,
    NULL as previous_year_trips,
    NULL as yoy_growth_pct
FROM (
    SELECT 
        hs.member_casual,
        hs.trip_year,
        hs.day_type,
        hs.total_trips,
        hs.avg_duration,
        hs.trip_hour,
        RANK() OVER (
            PARTITION BY hs.member_casual, hs.trip_year, hs.day_type 
            ORDER BY hs.total_trips DESC
        ) as hour_rank
    FROM hourly_summary hs
    WHERE hs.trip_year = 2024  -- Focus on current year for peak hours
) ranked_hours
WHERE ranked_hours.hour_rank <= 3  -- Top 3 peak hours only

ORDER BY analysis_type, member_casual, trip_year, day_name;

/*
EXPECTED INSIGHTS FOR MARKETING:
- Members show strong weekday patterns (commuter behavior) vs casual weekend patterns
- Peak hours reveal commute times for members vs recreational times for casual riders
- YoY growth shows expanding usage patterns and seasonal trends
- Weekend vs weekday duration differences indicate usage motivations

KEY MARKETING ACTIONS:
1. **Weekday Targeting**: Target casual riders during member peak hours with "join the commuters" messaging
2. **Weekend Campaigns**: Focus recreational messaging during casual rider weekend peaks
3. **Rush Hour Promotions**: Offer trial memberships during morning/evening commute times
4. **Day-Specific Offers**: Create Tuesday-Thursday promotions when casual usage is typically lower
5. **Seasonal Adjustments**: Adjust campaign timing based on YoY growth patterns
*/
