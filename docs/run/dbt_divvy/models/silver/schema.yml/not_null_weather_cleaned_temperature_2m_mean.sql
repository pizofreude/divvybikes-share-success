
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select temperature_2m_mean
from "divvy"."public_silver"."weather_cleaned"
where temperature_2m_mean is null



  
  
      
    ) dbt_internal_test