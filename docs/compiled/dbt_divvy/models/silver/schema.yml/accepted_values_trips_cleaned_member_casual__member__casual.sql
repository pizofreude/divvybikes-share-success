
    
    

with all_values as (

    select
        member_casual as value_field,
        count(*) as n_records

    from "divvy"."public_silver"."trips_cleaned"
    group by member_casual

)

select *
from all_values
where value_field not in (
    'member','casual'
)


