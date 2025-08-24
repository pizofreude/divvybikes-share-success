/*
BUSINESS QUESTION 1D: Bike Type Preferences and Advanced Behavioral Patterns
===========================================================================

INSIGHT OBJECTIVE:
Analyze bike type preferences, advanced usage patterns, and behavioral indicators
that distinguish casual riders from annual members. Focus on conversion signals.

MARKETING APPLICATION:
- Develop bike-type-specific membership messaging
- Identify "member-like" casual riders for targeted conversion
- Create behavior-based customer segments for personalized marketing
- Design membership trials based on usage intensity patterns
*/

-- Comprehensive Behavioral Analysis (2024 Focus with 2023 Comparison)
WITH bike_preferences AS (
    SELECT 
        member_casual,
        EXTRACT(year FROM started_at) as trip_year,
        rideable_type,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration_minutes,
        AVG(trip_distance_km) as avg_distance_km,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
            PARTITION BY member_casual, EXTRACT(year FROM started_at)
        ), 2) as percentage_of_user_trips
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, trip_year, rideable_type
),
usage_intensity AS (
    -- Analyze usage frequency patterns
    SELECT 
        member_casual,
        EXTRACT(year FROM started_at) as trip_year,
        EXTRACT(month FROM started_at) as trip_month,
        COUNT(DISTINCT DATE(started_at)) as days_active,
        COUNT(*) as total_trips,
        ROUND(COUNT(*) / COUNT(DISTINCT DATE(started_at)), 2) as avg_trips_per_day,
        AVG(ride_length_minutes) as avg_duration,
        CASE 
            WHEN COUNT(*) >= 100 THEN 'Heavy User (100+ trips)'
            WHEN COUNT(*) >= 50 THEN 'Moderate User (50-99 trips)' 
            WHEN COUNT(*) >= 20 THEN 'Regular User (20-49 trips)'
            WHEN COUNT(*) >= 10 THEN 'Light User (10-19 trips)'
            ELSE 'Occasional User (<10 trips)'
        END as usage_intensity_category
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, EXTRACT(year FROM started_at), EXTRACT(month FROM started_at)
),
member_like_casuals AS (
    -- Identify casual riders with member-like behavior patterns
    SELECT 
        trip_year,
        trip_month,
        COUNT(*) as total_casual_segments,
        SUM(CASE WHEN member_casual = 'casual' AND usage_intensity_category IN (
            'Heavy User (100+ trips)', 'Moderate User (50-99 trips)'
        ) THEN 1 ELSE 0 END) as high_intensity_casuals,
        SUM(CASE WHEN member_casual = 'casual' AND avg_trips_per_day >= 2 THEN 1 ELSE 0 END) as frequent_casual_users,
        AVG(CASE WHEN member_casual = 'casual' THEN avg_duration ELSE NULL END) as avg_casual_duration,
        AVG(CASE WHEN member_casual = 'member' THEN avg_duration ELSE NULL END) as avg_member_duration
    FROM usage_intensity
    GROUP BY trip_year, trip_month
),
seasonal_patterns AS (
    -- Seasonal behavior analysis
    SELECT 
        member_casual,
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'  
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
        END as season,
        EXTRACT(year FROM started_at) as trip_year,
        rideable_type,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration,
        COUNT(DISTINCT DATE(started_at)) as active_days
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, 
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'  
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
        END, 
        EXTRACT(year FROM started_at), 
        rideable_type
)

-- Main Results: Bike Type Preferences with YoY Comparison
SELECT 
    'BIKE_PREFERENCES' as analysis_type,
    bp.member_casual,
    bp.trip_year,
    bp.rideable_type,
    bp.trip_count,
    bp.percentage_of_user_trips,
    ROUND(bp.avg_duration_minutes, 2) as avg_duration_minutes,
    ROUND(bp.avg_distance_km, 2) as avg_distance_km,
    -- YoY Growth
    LAG(bp.trip_count) OVER (
        PARTITION BY bp.member_casual, bp.rideable_type 
        ORDER BY bp.trip_year
    ) as previous_year_count,
    ROUND(
        (bp.trip_count - LAG(bp.trip_count) OVER (
            PARTITION BY bp.member_casual, bp.rideable_type 
            ORDER BY bp.trip_year
        )) * 100.0 / NULLIF(LAG(bp.trip_count) OVER (
            PARTITION BY bp.member_casual, bp.rideable_type 
            ORDER BY bp.trip_year
        ), 0), 2
    ) as yoy_growth_percentage,
    NULL as conversion_metric
FROM bike_preferences bp

UNION ALL

-- Usage Intensity Distribution
SELECT 
    'USAGE_INTENSITY' as analysis_type,
    ui.member_casual,
    ui.trip_year,
    ui.usage_intensity_category as rideable_type,
    COUNT(*) as trip_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY ui.member_casual, ui.trip_year
    ), 2) as percentage_of_user_trips,
    ROUND(AVG(ui.avg_duration), 2) as avg_duration_minutes,
    ROUND(AVG(ui.avg_trips_per_day), 2) as avg_distance_km,
    NULL as previous_year_count,
    NULL as yoy_growth_percentage,
    NULL as conversion_metric
FROM usage_intensity ui
GROUP BY ui.member_casual, ui.trip_year, ui.usage_intensity_category

UNION ALL

-- Member-like Casual Conversion Opportunities
SELECT 
    'CONVERSION_POTENTIAL' as analysis_type,
    'casual' as member_casual,
    mlc.trip_year,
    'High-Intensity Casual Users' as rideable_type,
    mlc.high_intensity_casuals as trip_count,
    ROUND(mlc.high_intensity_casuals * 100.0 / mlc.total_casual_segments, 2) as percentage_of_user_trips,
    ROUND(mlc.avg_casual_duration, 2) as avg_duration_minutes,
    ROUND(mlc.avg_member_duration, 2) as avg_distance_km,
    NULL as previous_year_count,
    NULL as yoy_growth_percentage,
    ROUND(ABS(mlc.avg_casual_duration - mlc.avg_member_duration), 2) as conversion_metric
FROM member_like_casuals mlc

ORDER BY analysis_type, member_casual, trip_year, rideable_type;

/*
SEASONAL BIKE TYPE ANALYSIS - Separate Query for Seasonal Insights
*/
-- Query 2: Seasonal Patterns
WITH seasonal_patterns AS (
    -- Seasonal behavior analysis
    SELECT 
        member_casual,
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'  
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
        END as season,
        EXTRACT(year FROM started_at) as trip_year,
        rideable_type,
        COUNT(*) as trip_count,
        AVG(ride_length_minutes) as avg_duration,
        COUNT(DISTINCT DATE(started_at)) as active_days
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE EXTRACT(year FROM started_at) IN (2023, 2024)
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY member_casual, 
        CASE 
            WHEN EXTRACT(month FROM started_at) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(month FROM started_at) IN (3, 4, 5) THEN 'Spring'  
            WHEN EXTRACT(month FROM started_at) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(month FROM started_at) IN (9, 10, 11) THEN 'Fall'
        END, 
        EXTRACT(year FROM started_at), 
        rideable_type
)
SELECT 
    'SEASONAL_ANALYSIS' as analysis_type,
    sp.member_casual,
    sp.season,
    sp.trip_year,
    sp.rideable_type,
    sp.trip_count,
    ROUND(sp.trip_count * 100.0 / SUM(sp.trip_count) OVER (
        PARTITION BY sp.member_casual, sp.season, sp.trip_year
    ), 2) as seasonal_bike_percentage,
    ROUND(sp.avg_duration, 2) as avg_duration_minutes,
    sp.active_days,
    -- Season-over-season growth
    LAG(sp.trip_count) OVER (
        PARTITION BY sp.member_casual, sp.season, sp.rideable_type 
        ORDER BY sp.trip_year
    ) as previous_year_seasonal_count,
    ROUND(
        (sp.trip_count - LAG(sp.trip_count) OVER (
            PARTITION BY sp.member_casual, sp.season, sp.rideable_type 
            ORDER BY sp.trip_year
        )) * 100.0 / NULLIF(LAG(sp.trip_count) OVER (
            PARTITION BY sp.member_casual, sp.season, sp.rideable_type 
            ORDER BY sp.trip_year
        ), 0), 2
    ) as seasonal_yoy_growth
FROM seasonal_patterns sp
WHERE sp.trip_year = 2024  -- Focus on current year seasonal patterns
ORDER BY sp.member_casual, 
    CASE sp.season 
        WHEN 'Winter' THEN 1 WHEN 'Spring' THEN 2 
        WHEN 'Summer' THEN 3 WHEN 'Fall' THEN 4 
    END,
    sp.rideable_type;

/*
EXPECTED INSIGHTS FOR MARKETING:
- E-bike preferences may differ significantly between user types
- Usage intensity reveals "power users" among casual riders 
- Seasonal patterns show optimal timing for conversion campaigns
- Member-like casual behavior identifies prime conversion targets

KEY MARKETING ACTIONS:
1. **E-bike Promotions**: If casuals prefer e-bikes, emphasize e-bike access in membership
2. **Intensity-Based Targeting**: Target "Heavy User" and "Moderate User" casual riders
3. **Behavioral Mirroring**: Show casual riders how their usage compares to members
4. **Seasonal Campaigns**: Time conversion efforts during peak casual usage seasons
5. **Usage-Based Trials**: Offer membership trials to high-frequency casual users
6. **Bike-Type Messaging**: Tailor membership benefits based on bike type preferences
7. **Conversion Scoring**: Use usage intensity and duration similarity as conversion probability scores

ADVANCED SEGMENTATION OPPORTUNITIES:
- "Almost Members": Casual riders with member-like usage patterns
- "E-bike Enthusiasts": High e-bike usage casual riders
- "Weekend Warriors": High weekend casual usage with long durations  
- "Seasonal Converts": Users showing increasing usage intensity over time
*/
