
    
    

select
    ride_id as unique_field,
    count(*) as n_records

from "divvy"."public_gold"."trips_enhanced"
where ride_id is not null
group by ride_id
having count(*) > 1


