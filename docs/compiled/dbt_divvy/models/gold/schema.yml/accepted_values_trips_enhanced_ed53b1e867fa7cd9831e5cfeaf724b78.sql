
    
    

with all_values as (

    select
        usage_profile as value_field,
        count(*) as n_records

    from "divvy"."public_gold"."trips_enhanced"
    group by usage_profile

)

select *
from all_values
where value_field not in (
    'High Usage Casual','Medium Usage Casual','Low Usage Casual','High Usage Member','Regular Member','Unknown'
)


