
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select station_id
from "divvy"."public_gold"."station_performance"
where station_id is null



  
  
      
    ) dbt_internal_test