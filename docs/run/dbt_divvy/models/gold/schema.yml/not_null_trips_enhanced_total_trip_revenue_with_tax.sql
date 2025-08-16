
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_trip_revenue_with_tax
from "divvy"."public_gold"."trips_enhanced"
where total_trip_revenue_with_tax is null



  
  
      
    ) dbt_internal_test