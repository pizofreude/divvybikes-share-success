
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select analysis_date
from "divvy"."public_gold"."behavioral_analysis"
where analysis_date is null



  
  
      
    ) dbt_internal_test