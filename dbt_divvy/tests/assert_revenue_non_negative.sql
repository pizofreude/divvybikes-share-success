-- Test that revenue calculations are never negative
-- Returns records where revenue is negative (should be 0)

SELECT 
    ride_id,
    total_trip_revenue_with_tax,
    member_casual,
    ride_length_minutes
FROM {{ ref('trips_enhanced') }}
WHERE total_trip_revenue_with_tax < 0
