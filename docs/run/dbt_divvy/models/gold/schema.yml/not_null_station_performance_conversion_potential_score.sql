
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select conversion_potential_score
from "divvy"."public_gold"."station_performance"
where conversion_potential_score is null



  
  
      
    ) dbt_internal_test