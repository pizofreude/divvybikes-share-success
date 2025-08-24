/*
BUSINESS QUESTION 2B: Behavioral Patterns Resembling Existing Members
====================================================================

INSIGHT OBJECTIVE:
Identify casual riders whose behavior patterns closely match those of annual members.
Focus on trip timing, duration, frequency, and geographic patterns.

MARKETING APPLICATION:
- Target "member-like" casual riders with conversion campaigns
- Develop behavioral similarity scoring for lead prioritization
- Create personalized messaging based on existing member behavior patterns
- Design lookalike audience targeting for digital advertising
*/

-- Member vs Casual Behavioral Pattern Analysis (2024 Focus)
WITH member_behavioral_baseline AS (
    -- Establish member behavior baseline patterns
    SELECT 
        -- Trip timing patterns
        EXTRACT(dow FROM started_at) as day_of_week,
        EXTRACT(hour FROM started_at) as hour_of_day,
        -- Trip characteristics
        AVG(ride_length_minutes) as avg_duration,
        AVG(trip_distance_km) as avg_distance,
        -- Usage patterns
        COUNT(*) as total_trips,
        COUNT(DISTINCT DATE(started_at)) as active_days,
        COUNT(DISTINCT start_station_id) as unique_start_stations,
        COUNT(DISTINCT end_station_id) as unique_end_stations,
        -- Geographic patterns
        COUNT(DISTINCT (start_station_id::VARCHAR || '-' || end_station_id::VARCHAR)) as unique_routes,
        -- Trip purposes (inferred from timing and duration)
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 
            THEN 1 ELSE 0 
        END) as morning_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 
            THEN 1 ELSE 0 
        END) as evening_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) 
            THEN 1 ELSE 0 
        END) as weekend_trips
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'member'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY 
        EXTRACT(dow FROM started_at),
        EXTRACT(hour FROM started_at)
),
member_profile_summary AS (
    -- Aggregate member patterns into overall profile
    SELECT 
        AVG(avg_duration) as member_avg_duration,
        AVG(avg_distance) as member_avg_distance,
        -- Calculate typical member patterns
        CASE 
            WHEN AVG(CASE WHEN day_of_week BETWEEN 1 AND 5 THEN 1 ELSE 0 END) > 0 
            THEN AVG(CASE WHEN day_of_week BETWEEN 1 AND 5 THEN total_trips ELSE 0 END) / 
                 AVG(CASE WHEN day_of_week BETWEEN 1 AND 5 THEN 1 ELSE 0 END)
            ELSE 0 
        END as weekday_trip_rate,
        CASE 
            WHEN AVG(CASE WHEN day_of_week IN (0, 6) THEN 1 ELSE 0 END) > 0 
            THEN AVG(CASE WHEN day_of_week IN (0, 6) THEN total_trips ELSE 0 END) / 
                 AVG(CASE WHEN day_of_week IN (0, 6) THEN 1 ELSE 0 END)
            ELSE 0 
        END as weekend_trip_rate,
        -- Commute patterns
        AVG(morning_commute_trips + evening_commute_trips) as avg_commute_trips,
        AVG(weekend_trips) as avg_weekend_trips,
        -- Peak usage hours
        AVG(CASE WHEN hour_of_day BETWEEN 7 AND 9 THEN total_trips ELSE 0 END) as morning_peak_usage,
        AVG(CASE WHEN hour_of_day BETWEEN 17 AND 19 THEN total_trips ELSE 0 END) as evening_peak_usage
    FROM member_behavioral_baseline
),
casual_rider_analysis AS (
    -- Analyze casual rider behavior with member comparison metrics
    SELECT 
        start_station_name,
        DATE_TRUNC('month', started_at) as usage_month,
        COUNT(*) as monthly_trips,
        COUNT(DISTINCT DATE(started_at)) as active_days,
        COUNT(DISTINCT start_station_id) as unique_start_stations,
        COUNT(DISTINCT end_station_id) as unique_end_stations,
        COUNT(DISTINCT (start_station_id::VARCHAR || '-' || end_station_id::VARCHAR)) as unique_routes,
        -- Trip characteristics
        AVG(ride_length_minutes) as avg_duration,
        AVG(trip_distance_km) as avg_distance,
        -- Timing patterns
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
            THEN 1 ELSE 0 
        END) as weekday_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) IN (0, 6) 
            THEN 1 ELSE 0 
        END) as weekend_trips,
        -- Commute-like behavior
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 
            THEN 1 ELSE 0 
        END) as morning_commute_trips,
        SUM(CASE 
            WHEN EXTRACT(dow FROM started_at) BETWEEN 1 AND 5 
                AND EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 
            THEN 1 ELSE 0 
        END) as evening_commute_trips,
        -- Peak hour usage
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 7 AND 9 
            THEN 1 ELSE 0 
        END) as morning_peak_trips,
        SUM(CASE 
            WHEN EXTRACT(hour FROM started_at) BETWEEN 17 AND 19 
            THEN 1 ELSE 0 
        END) as evening_peak_trips
    FROM "divvy"."public_gold"."trips_enhanced"
    WHERE member_casual = 'casual'
        AND EXTRACT(year FROM started_at) = 2024
        AND ride_length_minutes > 0 
        AND ride_length_minutes < 1440
    GROUP BY start_station_name, DATE_TRUNC('month', started_at)
),
behavioral_similarity_scoring AS (
    -- Calculate behavioral similarity scores between casual riders and member baseline
    SELECT 
        cra.*,
        mps.member_avg_duration,
        mps.member_avg_distance,
        mps.weekday_trip_rate,
        mps.weekend_trip_rate,
        mps.avg_commute_trips,
        -- Calculate similarity scores (0-100 scale)
        -- Duration similarity (closer to member average = higher score)
        GREATEST(0, 100 - ABS(cra.avg_duration - mps.member_avg_duration) * 2) as duration_similarity_score,
        -- Distance similarity
        GREATEST(0, 100 - ABS(cra.avg_distance - mps.member_avg_distance) * 10) as distance_similarity_score,
        -- Weekday usage pattern similarity
        GREATEST(0, 100 - ABS(
            CASE 
                WHEN cra.monthly_trips > 0 THEN (cra.weekday_trips * 100.0 / cra.monthly_trips)
                ELSE 0 
            END - 
            CASE 
                WHEN (mps.weekday_trip_rate + mps.weekend_trip_rate) > 0 
                THEN (mps.weekday_trip_rate * 100.0 / (mps.weekday_trip_rate + mps.weekend_trip_rate))
                ELSE 0 
            END
        )) as weekday_pattern_similarity,
        -- Commute behavior similarity
        GREATEST(0, 100 - ABS(
            (cra.morning_commute_trips + cra.evening_commute_trips) - mps.avg_commute_trips
        ) * 5) as commute_similarity_score,
        -- Peak hour usage similarity
        GREATEST(0, 100 - ABS(
            (cra.morning_peak_trips + cra.evening_peak_trips) - 
            (mps.morning_peak_usage + mps.evening_peak_usage)
        ) * 3) as peak_hour_similarity_score,
        -- Geographic diversity (member-like station usage)
        CASE 
            WHEN cra.unique_routes >= 10 THEN 100
            WHEN cra.unique_routes >= 5 THEN 75
            WHEN cra.unique_routes >= 3 THEN 50
            ELSE 25
        END as geographic_diversity_score
    FROM casual_rider_analysis cra
    CROSS JOIN member_profile_summary mps
),
member_like_casual_identification AS (
    -- Identify and score casual riders with member-like behavior
    SELECT 
        start_station_name,
        usage_month,
        monthly_trips,
        active_days,
        avg_duration,
        avg_distance,
        weekday_trips,
        weekend_trips,
        morning_commute_trips + evening_commute_trips as total_commute_trips,
        unique_routes,
        -- Individual similarity scores
        duration_similarity_score,
        distance_similarity_score,
        weekday_pattern_similarity,
        commute_similarity_score,
        peak_hour_similarity_score,
        geographic_diversity_score,
        -- Overall behavioral similarity score (weighted average)
        ROUND(
            (duration_similarity_score * 0.20 +
             distance_similarity_score * 0.15 +
             weekday_pattern_similarity * 0.25 +
             commute_similarity_score * 0.20 +
             peak_hour_similarity_score * 0.10 +
             geographic_diversity_score * 0.10), 2
        ) as overall_similarity_score,
        -- Conversion likelihood based on behavior patterns
        CASE 
            WHEN (duration_similarity_score * 0.20 +
                  distance_similarity_score * 0.15 +
                  weekday_pattern_similarity * 0.25 +
                  commute_similarity_score * 0.20 +
                  peak_hour_similarity_score * 0.10 +
                  geographic_diversity_score * 0.10) >= 80 THEN 'Very High (80+ similarity)'
            WHEN (duration_similarity_score * 0.20 +
                  distance_similarity_score * 0.15 +
                  weekday_pattern_similarity * 0.25 +
                  commute_similarity_score * 0.20 +
                  peak_hour_similarity_score * 0.10 +
                  geographic_diversity_score * 0.10) >= 70 THEN 'High (70-79 similarity)'
            WHEN (duration_similarity_score * 0.20 +
                  distance_similarity_score * 0.15 +
                  weekday_pattern_similarity * 0.25 +
                  commute_similarity_score * 0.20 +
                  peak_hour_similarity_score * 0.10 +
                  geographic_diversity_score * 0.10) >= 60 THEN 'Medium (60-69 similarity)'
            ELSE 'Low (<60 similarity)'
        END as behavioral_conversion_likelihood
    FROM behavioral_similarity_scoring
    WHERE monthly_trips >= 5  -- Focus on users with meaningful activity
)

-- Main Results: Behavioral Similarity Analysis
SELECT 
    'MEMBER_LIKE_CASUAL_SUMMARY' as analysis_type,
    behavioral_conversion_likelihood,
    COUNT(*) as user_segment_count,
    ROUND(AVG(monthly_trips), 2) as avg_monthly_trips,
    ROUND(AVG(overall_similarity_score), 2) as avg_similarity_score,
    ROUND(AVG(duration_similarity_score), 2) as avg_duration_similarity,
    ROUND(AVG(commute_similarity_score), 2) as avg_commute_similarity,
    ROUND(AVG(weekday_pattern_similarity), 2) as avg_weekday_similarity,
    -- Marketing insights
    CASE 
        WHEN AVG(overall_similarity_score) >= 80 THEN 'Immediate Conversion Focus'
        WHEN AVG(overall_similarity_score) >= 70 THEN 'High Priority Targeting'
        WHEN AVG(overall_similarity_score) >= 60 THEN 'Medium Priority Nurturing'
        ELSE 'Low Priority or Lifestyle Messaging'
    END as marketing_approach,
    CASE 
        WHEN AVG(commute_similarity_score) >= 70 THEN 'Commuter Benefits Message'
        WHEN AVG(weekday_pattern_similarity) >= 70 THEN 'Consistency Benefits Message'
        ELSE 'General Convenience Message'
    END as recommended_messaging_theme
FROM member_like_casual_identification
GROUP BY behavioral_conversion_likelihood

UNION ALL

-- High-Priority Individual Conversion Targets
SELECT 
    'HIGH_PRIORITY_TARGETS' as analysis_type,
    start_station_name as behavioral_conversion_likelihood,
    1 as user_segment_count,
    monthly_trips as avg_monthly_trips,
    overall_similarity_score as avg_similarity_score,
    duration_similarity_score as avg_duration_similarity,
    commute_similarity_score as avg_commute_similarity,
    weekday_pattern_similarity as avg_weekday_similarity,
    'Individual Targeting' as marketing_approach,
    CASE 
        WHEN commute_similarity_score >= 70 AND total_commute_trips >= 8 THEN 'Commuter Membership Trial'
        WHEN weekday_pattern_similarity >= 80 THEN 'Weekday Regular Benefits'
        WHEN geographic_diversity_score >= 75 THEN 'Explorer Membership Benefits'
        ELSE 'General Convenience Benefits'
    END as recommended_messaging_theme
FROM member_like_casual_identification
WHERE overall_similarity_score >= 75  -- High similarity threshold
    AND monthly_trips >= 10  -- Frequent usage threshold

ORDER BY 
    analysis_type, avg_similarity_score DESC;

/*
EXPECTED INSIGHTS FOR MARKETING:

BEHAVIORAL SIMILARITY INDICATORS:
- Trip duration within 5 minutes of member average (12-15 minutes)
- Strong weekday usage pattern (60%+ weekday trips)
- Commute-like timing (7-9 AM, 5-7 PM trips)
- Geographic diversity (3+ unique routes per month)
- Consistent usage (15+ active days per month)

CONVERSION LIKELIHOOD SEGMENTS:
- Very High (80+ similarity): Immediate conversion campaigns
- High (70-79 similarity): Intensive nurturing with member benefits
- Medium (60-69 similarity): Educational content about membership value
- Low (<60 similarity): Lifestyle and convenience messaging

TARGETING STRATEGIES:
- Commuter-like casuals: Emphasize convenience and cost savings
- Geographic explorers: Highlight access to system-wide stations
- Consistent users: Focus on predictable monthly costs
- Peak-hour users: Target during high-usage times

KEY MARKETING ACTIONS:
1. **Behavioral Scoring**: Implement similarity scoring in marketing automation
2. **Lookalike Targeting**: Use high-similarity casuals for digital ad targeting
3. **Personalized Messaging**: Tailor content based on behavioral patterns
4. **Timing Optimization**: Target during individual peak usage periods
5. **Progressive Conversion**: Graduated messaging based on similarity scores
*/
