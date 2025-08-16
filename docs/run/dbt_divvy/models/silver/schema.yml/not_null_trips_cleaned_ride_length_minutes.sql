
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ride_length_minutes
from "divvy"."public_silver"."trips_cleaned"
where ride_length_minutes is null



  
  
      
    ) dbt_internal_test