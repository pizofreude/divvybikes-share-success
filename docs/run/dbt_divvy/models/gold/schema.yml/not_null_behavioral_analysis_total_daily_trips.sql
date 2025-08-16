
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_daily_trips
from "divvy"."public_gold"."behavioral_analysis"
where total_daily_trips is null



  
  
      
    ) dbt_internal_test