
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select started_at
from "divvy"."public_silver"."trips_cleaned"
where started_at is null



  
  
      
    ) dbt_internal_test