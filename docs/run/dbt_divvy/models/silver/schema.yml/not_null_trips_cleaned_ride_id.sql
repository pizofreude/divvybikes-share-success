
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ride_id
from "divvy"."public_silver"."trips_cleaned"
where ride_id is null



  
  
      
    ) dbt_internal_test