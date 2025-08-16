
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select member_casual
from "divvy"."public_silver"."trips_cleaned"
where member_casual is null



  
  
      
    ) dbt_internal_test