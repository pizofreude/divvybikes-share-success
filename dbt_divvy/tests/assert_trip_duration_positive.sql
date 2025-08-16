-- Test that ended_at is always after started_at
-- Returns records where this condition is violated (should be 0)

SELECT 
    ride_id,
    started_at,
    ended_at,
    ended_at - started_at AS duration
FROM {{ ref('trips_cleaned') }}
WHERE ended_at <= started_at
