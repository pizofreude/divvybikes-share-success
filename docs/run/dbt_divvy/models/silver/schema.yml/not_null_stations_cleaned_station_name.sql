
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select station_name
from "divvy"."public_silver"."stations_cleaned"
where station_name is null



  
  
      
    ) dbt_internal_test