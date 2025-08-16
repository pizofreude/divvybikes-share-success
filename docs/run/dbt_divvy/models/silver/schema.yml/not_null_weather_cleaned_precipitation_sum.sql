
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select precipitation_sum
from "divvy"."public_silver"."weather_cleaned"
where precipitation_sum is null



  
  
      
    ) dbt_internal_test