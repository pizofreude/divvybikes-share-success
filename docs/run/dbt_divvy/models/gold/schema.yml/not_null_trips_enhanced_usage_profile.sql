
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select usage_profile
from "divvy"."public_gold"."trips_enhanced"
where usage_profile is null



  
  
      
    ) dbt_internal_test