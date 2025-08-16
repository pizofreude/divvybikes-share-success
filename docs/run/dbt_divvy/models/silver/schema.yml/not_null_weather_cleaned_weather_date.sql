
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select weather_date
from "divvy"."public_silver"."weather_cleaned"
where weather_date is null



  
  
      
    ) dbt_internal_test