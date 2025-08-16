
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Test that coordinates are within reasonable bounds for Chicago area
-- Returns records with coordinates outside expected bounds (should be 0)

SELECT 
    ride_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng
FROM "divvy"."public_silver"."trips_cleaned"
WHERE 
    start_lat NOT BETWEEN 41.0 AND 43.0 
    OR start_lng NOT BETWEEN -89.0 AND -87.0
    OR end_lat NOT BETWEEN 41.0 AND 43.0 
    OR end_lng NOT BETWEEN -89.0 AND -87.0
  
  
      
    ) dbt_internal_test